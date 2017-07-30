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

cd $(dirname $0)

mkdir -p /storage
#================================================================
dpkg-reconfigure locales
#================================================================
apt-get update
apt-get upgrade -y
#================================================================
apt-get install -y apt-file
apt-file update
#================================================================
cat /etc/passwd | grep -q daniel || adduser daniel
cat /etc/group | grep -q 'sudo:.*daniel' || usermod -a -G sudo daniel
#================================================================
apt-get install -y mpg321
#================================================================
apt-get install -y axel
#================================================================
apt-get install -y cryptsetup
#================================================================
apt-get install -y samba
backup /etc/samba/smb.conf
release /etc/samba/smb.conf
smbpasswd -a daniel
#================================================================
apt-get install -y nginx
backup /etc/nginx/sites-available/default
release /etc/nginx/sites-available/default
#================================================================
apt-get install -y dnsmasq
backup /etc/dnsmasq.conf
release /etc/dnsmasq.conf
release /etc/dnsmasq.hosts
#================================================================
release /usr/local/bin/busybox 755
release /etc/busybox/httpd.conf
#================================================================
backup /etc/hostapd.conf
release /etc/hostapd.conf
#================================================================
backup /etc/sysctl.conf
release /etc/sysctl.conf
#================================================================
backup /etc/wpa_supplicant.conf
release /etc/wpa_supplicant.conf
#================================================================
backup /etc/rc.local
release /etc/rc.local 755
release /usr/local/etc/rc.local 755
release /usr/local/bin/ssh-socks-deamon 755
release /usr/local/bin/ssh-port-forward 755
#================================================================
cp -dr rfs/var/www/html/* /var/www/html/
chmod 755 /var/www/html/cgi-bin/*.cgi
#================================================================

