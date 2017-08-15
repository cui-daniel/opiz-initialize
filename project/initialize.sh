#!/bin/bash
function backup() {
	if [ -e $1 ]
	then
		if [ -e $1.backup ]
		then
			echo "backup: $1.backup exist"
		else
			echo "backup: $1 -> $1.backup"
			cp -a $1 $1.backup
		fi
	else
		echo "backup: $1 not exist"
	fi
}

function release() {
	if [ -e rfs/$1 ]
	then
		mkdir -p $(dirname $1)
		echo "release: rfs$1 -> $1"
		cp -dr rfs/$1 $1
		if [ -n "$2" ]
		then
			echo "release: change $1 mode to $2"
			chmod $2 $1
		fi
	else
		echo "release: rfs/$1 not exist"
	fi
}

function confirm() {
	unset input
	read -p "$1 [Y|n]: " -t 5 input
	echo
	[ -z "$input" -o "input" = "y" -o "$input" = "Y" ] && return 0
	return 1
}
cd $(dirname $0)

mkdir -p /storage
#================================================================
confirm "execute dpkg-reconfigure locales" && dpkg-reconfigure locales
#================================================================
confirm "execute apt-get update" && apt-get update
apt-get upgrade -y
#================================================================
apt-get install -y apt-file
confirm "execute apt-file update" && apt-file update
#================================================================
cat /etc/passwd | grep -q daniel || adduser daniel
cat /etc/group | grep -q 'sudo:.*daniel' || usermod -a -G sudo daniel
#================================================================
apt-get autoremove -y resolvconf
apt-get purge -y resolvconf
#================================================================
apt-get install -y sshpass
#================================================================
apt-get install -y mpg321
#================================================================
apt-get install -y axel
#================================================================
apt-get install -y ipcalc
#================================================================
apt-get install -y cryptsetup
#================================================================
apt-get install -y samba
#================================================================
apt-get install -y pdnsd
#================================================================
apt-get install -y isc-dhcp-server
#================================================================
apt-get install -y tftpd-hpa
#================================================================
apt-get install -y pxelinux
#================================================================
apt-get install -y nginx
backup /etc/nginx/sites-available/default
release /etc/nginx/sites-available/default
#================================================================
apt-get install -y privoxy
backup /etc/privoxy/config
release /etc/privoxy/config
release /etc/privoxy/ladder.action
#================================================================
backup /etc/sysctl.conf
release /etc/sysctl.conf
backup /etc/rc.local
release /etc/rc.local 755
release /usr/local/bin/busybox 755
release /usr/local/etc/rc.local 755
release /usr/local/etc/httpd.conf 644
release /usr/local/bin/device-manager 755
#================================================================
cp -dr rfs/var/www/html/* /var/www/html/
chmod 755 /var/www/html/cgi-bin/*.cgi
#================================================================
