#!/bin/sh

CONFIG_FILE2=/etc/docker-nat-net.ini
CONFIG_FILE=docker-nat-net.ini
IPTABLES_BIN=/usr/sbin/iptables

if [ ! -e ${IPTABLES_BIN} ]; then
	IPTABLES_BIN=/sbin/iptables
	if [ ! -e ${IPTABLES_BIN} ]; then
		echo "iptables not found" >&2
		exit 1
	fi
fi

if [ ! -f ${CONFIG_FILE} ]; then
	if [ -f ${CONFIG_FILE2} ]; then
		CONFIG_FILE=${CONFIG_FILE2}
	else
		echo "docker-nat-net.ini not found" >&2
		exit 1
	fi
fi

create_network()
{
	NET_NAME=${1}
	docker network create --attachable \
		--opt 'com.docker.network.bridge.enable_ip_masquerade=false'\
		${NET_NAME}
		#--opt "com.docker.network.bridge.name=${NET_NAME}"\
}

up_network()
{
	NET_NAME=${1}
	PIP=${2}

	BR_SUBNET=$(docker network inspect ${NET_NAME} | jq -r '.[].IPAM.Config[].Subnet')
	if [ -z $BR_SUBNET ]; then
		echo Network ${NET_NAME} doesn\'t exist >&2
		return 1
	fi

	BR_IF=$(docker network inspect ${NET_NAME}| jq -r '.[].Options."com.docker.network.bridge.name"')
	if [ "${BR_IF}" = "null" ]; then
		BR_IF=$(docker network inspect ${NET_NAME}| jq -r '.[].Id' | awk '{print "br-"substr ($0, 0, 12)}')
	fi

	echo ${NET_NAME} ${BR_SUBNET} ${BR_IF}
	${IPTABLES_BIN} -t nat -A POSTROUTING -s ${BR_SUBNET} ! -o ${BR_IF} -j SNAT --to-source ${PIP} 
	${IPTABLES_BIN} -t nat -A DOCKER -i ${BR_IF} -j RETURN
}

down_network()
{
	NET_NAME=${1}
	BR_SUBNET=$(docker network inspect ${NET_NAME} | jq -r '.[].IPAM.Config[].Subnet')
	if [ -z $BR_SUBNET ]; then
		echo Network ${NET_NAME} doesn\'t exist >&2
		return 1
	fi

	BR_IF=$(docker network inspect ${NET_NAME}| jq -r '.[].Options."com.docker.network.bridge.name"')
	if [ "${BR_IF}" = "null" ]; then
		BR_IF=$(docker network inspect ${NET_NAME}| jq -r '.[].Id' | awk '{print "br-"substr ($0, 0, 12)}')
	fi

	${IPTABLES_BIN}  -t nat -S | grep ${BR_IF} | grep -v 'DNAT' | while read -r line ; do
		ARGS=$(echo $line | sed 's/^-A/-D/')
		echo ${IPTABLES_BIN} -t nat $ARGS
		${IPTABLES_BIN} -t nat $ARGS
	done
}


parse_config()
{
	CB=${1}
	grep -v '^#' ${CONFIG_FILE} |
	while IFS=, read -r net ip
	do
		# not working on ash
		#if [ ${net}  =~ ^#.* ]; then continue; fi
		if [ -z ${net} ]; then continue; fi

		if [ -z ${CB} ]; then
			echo network ${net} ${ip}
		else
			${CB} ${net} ${ip}
		fi
	done
	#done < ${CONFIG_FILE}
	#done < <(grep -v '^#' ${CONFIG_FILE})
}

case "$1" in
'up')
	parse_config up_network
;;
'down')
	parse_config down_network
;;
'reload')
	parse_config down_network
	parse_config up_network
;;
'create')
	parse_config create_network 
;;
'config')
	parse_config
;;
*)
echo "Usage: $0 {up|down|reload|create|config}" >&2
exit 1
;;
esac

