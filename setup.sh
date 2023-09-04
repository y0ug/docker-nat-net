#!/bin/sh
BASEDIR=$(dirname $0)

setup()
{
	cp $BASEDIR/docker-nat-net.sh /usr/local/bin/docker-nat-net.sh
	chmod +x /usr/local/bin/docker-nat-net.sh
	touch /etc/docker-nat-net.ini
	if type systemctl > /dev/null; then
		cp $BASEDIR/docker-nat-net.service /etc/systemd/system/docker-nat-net.service
		systemctl daemon-reload
		systemctl enable
		systemctl restart docker-nat-net.service
	else	
		cp $BASEDIR/docker-nat-net.openrc /etc/init.d/docker-nat-net
		chmod +x /etc/init.d/docker-nat-net
		rc-update add docker-nat-net default
		service docker-nat-net start
	fi	
}

uninstall()
{
	if type systemctl > /dev/null; then
		systemctl stop docker-nat-net.service
		systemctl disable docker-nat-net
		rm /etc/systemd/system/docker-nat-net.service
		systemctl daemon-reload
	else
		service docker-nat-net stop
		rc-update delete docker-nat-net -a
		rm /etc/init.d/docker-nat-net
	fi
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

