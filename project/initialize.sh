#!/bin/bash
function _backup() {
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

function _release() {
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

function _confirm() {
	unset input
	read -p "$1 [Y|n]: " -t 5 input
	echo
	[ -z "$input" -o "$input" = "y" -o "$input" = "Y" ] && return 0
	return 1
}

function _uninstall() {
	result=1
	dpkg --get-selections | grep -w $1 | grep -w install && apt-get autoremove -y $1 && result=0
	dpkg --get-selections | grep -w $1 | grep -w deinstall && apt-get purge -y $1 && result=0
	return $result
}

function _install() {
	[ -z "$APT_OPTIONS" ] && apt-get install -y $@
	[ -z "$APT_OPTIONS" ] || apt-get -o "$APT_OPTIONS" install -y $@
}

function _update() {
	[ -z "$APT_OPTIONS" ] && apt-get update
	[ -z "$APT_OPTIONS" ] || apt-get -o "$APT_OPTIONS" update
}

function _upgrade() {
	[ -z "$APT_OPTIONS" ] && apt-get upgrade -y
	[ -z "$APT_OPTIONS" ] || apt-get -o "$APT_OPTIONS" upgrade -y
}

function _parameter() {
	key=$1
	shift
	for item in $@
	do
		if [ "${item%%=*}" = $key ]
		then
			echo "${item#*=}"
			break
		fi
	done
}

while ps aux | grep -w apt | grep -v grep
do
	sleep 5
done

cd $(dirname $0)
APT_OPTIONS=$(_parameter --apt-options $@)
#================================================================
mkdir -p /storage
sed -i 's/orangepizero/daniel-mobile/g' /etc/hostname /etc/hosts
#================================================================
cat /etc/passwd | grep -q daniel || adduser daniel
cat /etc/group | grep -q 'sudo:.*daniel' || usermod -a -G sudo daniel
#================================================================
REBOOT=0
_uninstall resolvconf && REBOOT=1
_uninstall network-manager && REBOOT=1
_uninstall avahi-autoipd && REBOOT=1
_uninstall armbian-config && REBOOT=1
cp -a /boot/bin /boot/bin.keep
apt-get autoremove -y linux-jessie-root-orangepizero
rm -rf /boot/bin
mv /boot/bin.keep /boot/bin
update-initramfs -u
apt-get autoremove -y
dpkg --get-selections | grep deinstall | awk '{print $1}' | xargs apt-get purge -y
[ "$REBOOT" = "1" ] && reboot
#================================================================
_confirm "execute dpkg-reconfigure locales" && dpkg-reconfigure locales
#================================================================
_confirm "execute apt-get update" && _update
_confirm "execute apt-get upgrade" && _upgrade
#================================================================
_install apt-file
_confirm "execute apt-file update" && apt-file update
#================================================================
_install sshpass
#================================================================
_install mpg321
#================================================================
_install axel
#================================================================
_install ipcalc
#================================================================
_install cryptsetup
#================================================================
_install samba
#================================================================
_install android-tools-adb
#================================================================
if [ ! -e /usr/local/sbin/pdnsd ]
then
	git clone https://gitorious.org/pdnsd/pdnsd.git
	cd pdnsd/
	./configure
	make
	make install
	rm /usr/local/etc/pdnsd.conf.sample
	cd ..
	rm -rf pdnsd
fi
#================================================================
_install isc-dhcp-server
#================================================================
_install tftpd-hpa
#================================================================
_install syslinux-common
_install pxelinux
#================================================================
_install nginx php5-fpm
_backup /etc/nginx/sites-available/default
_release /etc/nginx/sites-available/default
#================================================================
apt-get install -y privoxy
_backup /etc/privoxy/config
_release /etc/privoxy/config
_release /etc/privoxy/ladder.action
#================================================================
_backup /etc/sysctl.conf
_backup /etc/rc.local
_release /etc/sysctl.conf
_release /etc/rc.local 755
_release /etc/network/interfaces
_release /usr/local/bin/busybox 755
_release /usr/local/etc/rc.local.common 755
_release /usr/local/etc/rc.local.hotspot 755
_release /usr/local/etc/rc.local.station 755
_release /usr/local/etc/httpd.conf 644
_release /usr/local/bin/device-manager 755
/usr/local/bin/device-manager initialize hotspot
#================================================================
cp -dr rfs/var/www/html/* /var/www/html/
ln -s /srv/tftp/boot /var/www/html/boot
chmod 755 /var/www/html/cgi-bin/*.cgi
#================================================================
