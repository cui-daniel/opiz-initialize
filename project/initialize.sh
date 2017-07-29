#!/bin/bash
function backup() {
	[ -e $1 ] || return
	[ -e $1.backup ] || cp -a $1 $1.backup
}

function release() {
	mkdir -p $(dirname $1)
	cp -a rfs/$1 $1
	[ -n "$2" ] && chmod $2 $1
}

cd $(dirname $1)

mkdir -p /storage

#================================================================
apt-get update
apt-get upgrade
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
backup /etc/wpa_supplicant.conf
release /etc/wpa_supplicant.conf
#================================================================
backup /etc/rc.local
release /etc/rc.local 755
release /usr/local/etc/rc.local 755
release /usr/local/bin/ssh-socks-deamon 755
release /usr/local/bin/ssh-port-forward 755
#================================================================
release /var/www/html
chmod 755 /var/www/html/cgi-bin/*.cgi
#================================================================
