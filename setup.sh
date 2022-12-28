#!/bin/sh
BASEDIR=$(dirname $0)

setup()
{
	cp $BASEDIR/docker-nat-net.sh /usr/local/bin/docker-nat-net.sh
	chmod +x /usr/local/bin/docker-nat-net.sh
	cp $BASEDIR/docker-nat-net.service /etc/systemd/system/docker-nat-net.service
	touch /etc/docker-nat-net.ini
	systemctl daemon-reload
}

uninstall()
{
	systemctl stop docker-nat-net
	systemctl disable docker-nat-net
	rm /etc/systemd/system/docker-nat-net.service
	systemctl daemon-reload
	rm /usr/local/bin/docker-nat-net.sh
}

case "$1" in
'install')
	setup	
;;
'uninstall')
   	uninstall 
;;
*)
	setup
;;
esac

