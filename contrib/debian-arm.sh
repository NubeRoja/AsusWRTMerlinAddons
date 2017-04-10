#!/bin/sh

export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

BOLD="\033[1m"
NORM="\033[0m"
INFO="${BOLD}Info: $NORM"
ERROR="${BOLD}*** Error: $NORM"
WARNING="${BOLD}* Warning: $NORM"

echo -e "$INFO This script was created by NubeRoja."
echo -e "$INFO but is entirely based on this excellent web page created by TeHashX:"
echo -e "$INFO https://www.hqt.ro/how-to-install-debian-jessie-arm/"
echo -e "$INFO with some tricks added by NubeRoja"
echo -e "$WARNING This scripts depends on a previous installation of entware-ng or optware-ng"
cd /opt || ( echo -e "$ERROR entware-ng or optware-ng not installed. Exiting" && exit 1 )
echo -e "$INFO Downloading filesystem" 
wget -c -O debian_jessie8.6-arm_clean.tgz http://goo.gl/Yp7CwA
echo -e "$INFO Untar filesystem, please wait..."
tar -xzf ./debian_jessie8.6-arm_clean.tgz

echo -e "$INFO Creating debian init.d script"
cat > /opt/etc/init.d/S99debian << EOF
#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

CHROOT_DIR=\$(readlink -f /opt)/debian
RUNNING=\$(mount | grep -q "\$CHROOT_DIR" && echo true || echo false)
# EXT_DIR=/tmp/mnt/LaCie/Media/
CHROOT_SERVICES_LIST=/opt/etc/chroot-services.list
if [ ! -e "\$CHROOT_SERVICES_LIST" ]; then
	echo "Please, define Debian services to start in \$CHROOT_SERVICES_LIST first!"
	echo "One service per line. Hint: this is a script names from Debian's /etc/init.d/"
	exit 1
fi

start() {
	if \$RUNNING; then
		echo "Chroot'ed services seems to be already started, exiting..."
		exit 1
	fi
	echo "Starting chroot'ed Debian services..."
	for dir in dev proc sys; do
		mount -o bind /\$dir \$CHROOT_DIR/\$dir
	done
	[ -z "\$EXT_DIR" ] || mount -o bind \$EXT_DIR \$CHROOT_DIR/mnt
	while IFS= read -r line; do
		chroot "\$CHROOT_DIR" "/etc/init.d/\$line" start
		sleep 2
	done < \$CHROOT_SERVICES_LIST
}
	
stop() {
	if ! \$RUNNING; then
		echo "Chroot'ed services seems to be already stopped, exiting..."
		exit 1
	fi
	echo "Stopping chroot'ed Debian services..."
	while IFS= read -r line; do
		chroot "\$CHROOT_DIR" "/etc/init.d/\$line" stop
		sleep 2
	done < \$CHROOT_SERVICES_LIST
	mount | grep \$CHROOT_DIR | awk '{print \$3}' | xargs umount -l
}
	
restart() {
	if ! \$RUNNING; then
		echo "Chroot'ed services seems to be already stopped"
		start
	else
		echo "Stopping chroot'ed Debian services..."
		while IFS= read -r line; do
			chroot "\$CHROOT_DIR" "/etc/init.d/\$line" stop
			sleep 2
		done < \$CHROOT_SERVICES_LIST
		mount | grep \$CHROOT_DIR | awk '{print \$3}' | xargs umount -l
		echo "Restarting chroot'ed Debian services..."
	  for dir in dev proc sys; do
			mount -o bind /\$dir \$CHROOT_DIR/\$dir
	  done
	  [ -z "\$EXT_DIR" ] || mount -o bind \$EXT_DIR \$CHROOT_DIR/mnt
		while IFS= read -r line; do
			chroot "\$CHROOT_DIR" "/etc/init.d/\$line" start
			sleep 2
		done < \$CHROOT_SERVICES_LIST
	fi
}	

enter() {
	[ -z "\$EXT_DIR" ] || mount -o bind \$EXT_DIR \$CHROOT_DIR/mnt
	mount -o bind /dev/ /opt/debian/dev/
	mount -o bind /dev/pts /opt/debian/dev/pts
	mount -o bind /proc/ /opt/debian/proc/
	mount -o bind /sys/ /opt/debian/sys/
	clear
	chroot /opt/debian /bin/bash
}

status() {
	if \$RUNNING; then
		echo "Chroot'ed services running..."
	else
		echo "Chroot'ed services not running!"
	fi
}

case "\$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		restart
		;;
	enter)
		enter
		;;	
	status|check)
		status
		;;
	*)
		echo "Usage: (start|stop|restart|enter|status)"
		exit 1
		;;
esac
echo Done.
exit 0
EOF

chmod 755 /opt/etc/init.d/S99debian

touch /opt/etc/chroot-services.list
ln -s /opt/etc/init.d/S99debian /opt/bin/debian

# Configure locales and timezone
echo "Europe/Madrid" > /opt/debian/etc/timezone
sed -i -e 's/# es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /opt/debian/etc/locale.gen

# Configure bash ls colorized
sed -i -e 's/# eval \"`dircolors`\"/eval \"`dircolors`\"/' /opt/debian/root/.bashrc
sed -i -e 's/# alias l/alias l/' /opt/debian/root/.bashrc

while : ; do
	clear
	echo "-----------------------------------------------------------------------"
	echo -e "$INFO Setup complete. debian $(debian)"
	echo "-----------------------------------------------------------------------"
	echo -n "Want to updrade debian packages? [ y / n ]: "
	read choice
	case $choice in
		y|Y)
			chroot /opt/debian/ apt update
			chroot /opt/debian/ apt upgrade -y
			exit 0
			;;
		n|N)
			exit 0
			;;
		*)
			echo
			echo "Type y to update debian and finish installation"
			echo "Type n to finish installation without update"
			echo "Press Enter key to continue"
			read readEnterKey
			;;
	esac
done

