#!/bin/sh

export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

BOLD="\033[1m"
NORM="\033[0m"
INFO="${BOLD}Info: $NORM"
ERROR="${BOLD}*** Error: $NORM"
WARNING="${BOLD}* Warning: $NORM"
INPUT="${BOLD}=> $NORM"

backup() {
	echo -e "$WARNING Found previous $2 installation, saving..."
	backupdir="$1"-bak_"$(date +'%F_%H-%M')"
	mv "$1" "$backupdir"
	echo -e "$INFO Backup of $1 created in $backupdir"
	sleep 2
}

swapfile() {
	echo -e "$INFO Creating a $1 MB swap file..."
	echo -e "$INFO This could take a while, be patient..."
	dd if=/dev/zero of=/opt/swap bs=1024 count=$((1024*$1))
	mkswap /opt/swap
	chmod 0600 /opt/swap
	swapon /opt/swap
	echo -n "Press [Enter] key to continue..."
	read readEnterKey
}

cd /tmp || exit 0

clear
echo -e "$INFO This script was created by ryzhov_al and modified by TeHashX."
echo -e "$INFO Thanks @zyxmon \& @ryzhov_al for New Generation Entware"
echo -e "$INFO and @Rmerlin for his awesome firmwares"
sleep 2
echo -e "$INFO This script will guide you through the Entware-NG installation."
echo -e "$INFO Script modifies only \"entware-ng\" folder on the chosen drive,"
echo -e "$INFO no other data will be touched. Existing installation will be"
echo -e "$INFO replaced with this one. Also some start scripts will be installed,"
echo -e "$INFO the old ones will be saved on partition where Entware-NG is installed"
echo -e "$INFO like /tmp/mnt/sda1/jffs_scripts_backup.tgz"
echo

if [ ! -d /jffs/scripts ] ; then
	echo -e "$ERROR Please \"Enable JFFS partition\" from \"Administration > System\""
	echo -e "$ERROR from router web UI: www.asusrouter.com/Advanced_System_Content.asp"
	echo -e "$ERROR then reboot router and try again. Exiting..."
	exit 1
fi

case $(uname -m) in
	armv7l)
		PART_TYPES='ext2|ext3|ext4'
		INST_URL='http://pkg.entware.net/binaries/armv7/installer/entware_install.sh'
		ENT_FOLD='entware.arm'
		ENTNG_FOLD='entware-ng.arm'
		OPT_FOLD='asusware.arm'
		OPTNG_FOLD='optware-ng.arm'
		;;
	mips)
		PART_TYPES='ext2|ext3'
		INST_URL='http://pkg.entware.net/binaries/mipsel/installer/installer.sh'
		ENT_FOLD='entware'
		ENTNG_FOLD='entware-ng'
		OPT_FOLD='asusware'
		OPTNG_FOLD='optware-ng'
		;;
	*)
		echo "This is unsupported platform, sorry."
		;;
esac

i=1 # Will count available partitions (+ 1)
echo -e "$INFO Looking for available partitions..."
for mounted in $(/bin/mount | grep -E "$PART_TYPES" | cut -d" " -f3) ; do
	echo "[$i] --> $mounted"
	eval mounts$i="$mounted"
	i=$((i+1))
done

if [ "$i" = "1" ] ; then
	echo -e "$ERROR No $PART_TYPES partitions available. Exiting..."
	exit 1
fi

echo -en "$INPUT Please enter partition number or 0 to exit\n$BOLD[0-$((i-1))]$NORM: "
read partitionNumber
[ "$partitionNumber" = "0" ] && echo -e "$INFO Exiting..." && exit 0
[ "$partitionNumber" -gt $((i-1)) ] && echo -e "$ERROR Invalid partition number! Exiting..." && exit 1

entPartition=""
eval entPartition=\$mounts"$partitionNumber"
echo -e "$INFO $entPartition selected.\n"
entwareFolder=$entPartition/$ENT_FOLD
entFolder=$entPartition/$ENTNG_FOLD
asuswareFolder=$entPartition/$OPT_FOLD
optwareFolder=$entPartition/$OPTNG_FOLD

[ -f /opt/etc/init.d/rc.unslung ] && echo -e "$WARNING stopping running services..." && /opt/etc/init.d/rc.unslung stop
[ -d /opt/debian ] && echo -e "$WARNING Found chrooted-debian installation, stopping debian..." && debian stop
[ -d $entwareFolder ] && backup $entwareFolder $ENT_FOLD
[ -d $entFolder ] && backup $entFolder $ENTNG_FOLD
[ -d $asuswareFolder ] && backup $asuswareFolder $OPT_FOLD
[ -d $optwareFolder ] && backup $optwareFolder $OPTNG_FOLD

echo -e "$INFO Creating $entFolder folder..."
mkdir $entFolder

[ -d /tmp/opt ] && echo -e "$WARNING Refreshing old /tmp/opt symlink..."
ln -sf $entFolder /tmp/opt && echo -e "$INFO Created /tmp/opt symlink..."

if [ -d /jffs/scripts ]; then
	echo -e "$INFO Creating /jffs scripts backup..."
	tar -czf $entPartition/jffs_scripts_backup_"$(date +'%F_%H-%M')".tgz /jffs/scripts/* >/dev/nul
fi

echo -e "$INFO Creating new /jffs scripts..."
# premount
cat > /jffs/scripts/pre-mount << EOF
#!/bin/sh
# /jffs/scripts/pre-mount
# first argument is the device to be mounted (e.g. /dev/sda1/)
# Check filesystem or mount swap partition
TAG=\$(basename "\$0")_\$@
FSTYPE=\$(fdisk -l "\${1:0:8}" | grep "\$1" | cut -c55-65)

case "\$FSTYPE" in
	"Linux")
		logger -t \$TAG "Checking \$FSTYPE filesystem"
		LOG=\$(e2fsck -p \$1)
		;;
	"Linux swap")
		logger -t \$TAG "Mounting swap partition"
		swapon \$1 && LOG="Swap partition mounted" || LOG="Device busy. Already mounted?"
		;;
	"HPFS|NTFS")
		logger -t \$TAG "Checking \$FSTYPE filesystem"
		LOG=\$(ntfsck -a \$1)
		;;
	"Win95*|FAT*")
		logger -t \$TAG "Checking \$FSTYPE filesystem"
		LOG=\$(fatfsck -a \$1)
		;;
	*)
		LOG="Unknow filesystem type \$FSTYPE on \$1. No filesystem check available"
		;;
esac
logger -t \$TAG \$LOG
EOF

chmod +x /jffs/scripts/pre-mount

# post-mount
cat > /jffs/scripts/post-mount << EOF
#!/bin/sh
# /jffs/scripts/post-mount
# first argument is the partition mounted (e.g. /tmp/mnt/usbdisklabel/)
# If partition is the entware volume
#       Create /opt symlink
#       Mount swap file if exists
#	Start Entware services
TAG=\$(basename "\$0")_\$@

if [ "\$1" = "$entPartition" ] ; then
        ln -nsf \$1/entware-ng.arm /tmp/opt && logger -t \$TAG "Created entware-ng symlink"
        [ -f /opt/swap ] && swapon /opt/swap && logger -t \$TAG "Mounted swap file..."
        logger -t \$TAG "Running rc.unslung to start Entware services ..."
        /opt/etc/init.d/rc.unslung start
fi
EOF

chmod +x /jffs/scripts/post-mount

# unmount
cat > /jffs/scripts/unmount << EOF
#!/bin/sh
# /jffs/scripts/unmount
# first argument is the partition to be unmounted (e.g. /tmp/mnt/usbdisklabel/)
# If partition is the entware volume
#       Stop entware services
#       Unmount swap file if exists
#	Stop chrooted services if debian exists
OPT=\$(dirname \$(readlink /tmp/opt))
TAG=\$(basename "\$0")_\$@
if [ "\$1" == "\$OPT" ] ; then
        services stop
        [ -f /opt/swap ] && swapoff /opt/swap && logger -t \$TAG "Unmounting swap file..."
	[ -d /opt/debian ] && debian stop
fi
EOF

chmod +x /jffs/scripts/unmount

if [ "$(nvram get jffs2_scripts)" != "1" ] ; then
        echo -e "$INFO Enabling custom scripts and configs from /jffs..."
        nvram set jffs2_scripts=1
        nvram commit
fi

wget -qO - $INST_URL | sh
opkg install terminfo

# Swap file
while :
do
        clear
        echo -e "Router model $(cat "/proc/sys/kernel/hostname")"
        echo "--------------------------------------------------"
        echo "SWAP FILE CREATION"
        echo "If you have a swap partition,"
        echo "   the pre-mount script will mount it every boot"
        echo "   select 4 for skip SWAP FILE Creation"
        echo "--------------------------------------------------"
        echo "Choose swap file size (Highly Recommended)"
        echo "1. 512MB"
        echo "2. 1024MB"
        echo "3. 2048MB (recommended for MySQL Server or PlexMediaServer)"
        echo "4. Skip this step, I already have a swap file / partition"
        echo "   or I don't want to create one right now"
        echo -n "Enter your choice [ 1 - 4 ] : "
        read choice
        case $choice in
        1)
                swapfile 512
                break
                ;;
        2)
                swapfile 1024
                break
                ;;
        3)
                swapfile 2048
                break
                ;;
        4)
                break
                ;;
        *)
                echo "ERROR: INVALID OPTION!"
                echo "Press 1 to create a 512MB swap file"
                echo "Press 2 to create a 1024MB swap file"
                echo "Press 3 to create a 2048MB swap file (for Mysql or Plex)"
                echo "Press 4 to skip swap creation (not recommended)"
                echo "Press [Enter] key to continue..."
                read readEnterKey
                ;;
        esac
done

cat > /opt/bin/services << EOF
#!/bin/sh

export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

case "\$1" in
        start)
                sh /opt/etc/init.d/rc.unslung start
                ;;
        stop)
                sh /opt/etc/init.d/rc.unslung stop
                ;;
        restart)
                sh /opt/etc/init.d/rc.unslung stop
                echo -e Restarting Entware-NG Installed Services...
                sleep 2
                sh /opt/etc/init.d/rc.unslung start
                ;;
        check)
                sh /opt/etc/init.d/rc.unslung check
                ;;
        *)
                echo "Usage: services {start|stop|restart|check}" >&2
                exit 3
                ;;
esac
EOF

chmod +x /opt/bin/services

cat << EOF

Congratulations! If there are no errors above then Entware-NG is successfully initialized.

Found a Bug? Please report at https://github.com/Entware-ng/Entware-ng/issues

Type 'opkg install <pkg_name>' to install necessary package.

EOF
