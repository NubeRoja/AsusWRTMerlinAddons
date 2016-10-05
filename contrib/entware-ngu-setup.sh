#!/bin/sh

export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin$PATH

BOLD="\033[1m"
NORM="\033[0m"
INFO="$BOLD Info: $NORM"
ERROR="$BOLD *** Error: $NORM"
WARNING="$BOLD * Warning: $NORM"
INPUT="$BOLD => $NORM"

i=1 # Will count available partitions (+ 1)
cd /tmp

echo -e $INFO This script was created by ryzhov_al and modified by TeHashX.
echo -e $INFO Thanks @zyxmon \& @ryzhov_al for New Generation Entware
echo -e $INFO and @Rmerlin for his awesome firmwares
sleep 2
echo -e $INFO This script will guide you through the Entware-NG installation.
echo -e $INFO Script modifies only \"entware-ng\" folder on the chosen drive,
echo -e $INFO no other data will be touched. Existing installation will be
echo -e $INFO replaced with this one. Also some start scripts will be installed,
echo -e $INFO the old ones will be saved on partition where Entware-NG is installed
echo -e $INFO like /tmp/mnt/sda1/jffs_scripts_backup.tgz
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
    ENT_FOLD='entware-ng.arm'
    ;;
  mips)
    PART_TYPES='ext2|ext3'
    INST_URL='http://pkg.entware.net/binaries/mipsel/installer/installer.sh'
    ENT_FOLD='entware-ng'
    ;;
  *)
    echo "This is unsupported platform, sorry."
    ;;
esac

echo -e "$INFO Looking for available partitions..."
for mounted in `/bin/mount | grep -E "$PART_TYPES" | cut -d" " -f3` ; do
  isPartitionFound="true"
  echo "[$i] --> $mounted"
  eval mounts$i=$mounted
  i=`expr $i + 1`
done

if [ $i == "1" ] ; then
  echo -e "$ERROR No $PART_TYPES partitions available. Exiting..."
  exit 1
fi

echo -en "$INPUT Please enter partition number or 0 to exit\n$BOLD[0-`expr $i - 1`]$NORM: "
read partitionNumber
if [ "$partitionNumber" == "0" ] ; then
  echo -e $INFO Exiting...
  exit 0
fi

if [ "$partitionNumber" -gt `expr $i - 1` ] ; then
  echo -e "$ERROR Invalid partition number! Exiting..."
  exit 1
fi

eval entPartition=\$mounts$partitionNumber
echo -e "$INFO $entPartition selected.\n"
entFolder=$entPartition/$ENT_FOLD
entarmFolder=$entPartition/$ENT_FOLD
entwareFolder=$entPartition/entware
entwarearmFolder=$entPartition/entware.arm
asuswareFolder=$entPartition/asusware
asuswarearmFolder=$entPartition/asusware.arm
optwareFolder=$entPartition/optware-ng
optwarearmFolder=$entPartition/optware-ng.arm

if [ -d /opt/debian ]
then
  echo -e "$WARNING Found chrooted-debian installation, stopping..."
  debian stop
fi

if [ -f /jffs/scripts/services-stop ]
then
  echo -e "$WARNING stopping running services..."
  /jffs/scripts/services-stop
fi

if [ -d $entFolder ] ; then
  echo -e "$WARNING Found previous entware-ng installation, saving..."
  mv $entFolder $entFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $entarmFolder ] ; then
  echo -e "$WARNING Found previous entware-ng.arm installation, saving..."
  mv $entarmFolder $entarmFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $entwareFolder ] ; then
  echo -e "$WARNING Found old entware installation, saving..."
  mv $entwareFolder $entwareFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $entwarearmFolder ] ; then
  echo -e "$WARNING Found previous entware-ng installation, saving..."
  mv $entwarearmFolder $entwarearmFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $asuswareFolder ] ; then
  echo -e "$WARNING Found old optware installation, saving..."
  mv $asuswareFolder $asuswareFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $asuswarearmFolder ] ; then
  echo -e "$WARNING Found old optware.arm installation, saving..."
  mv $asuswarearmFolder $asuswarearmFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $optwareFolder ] ; then
  echo -e "$WARNING Found optware-ng installation, saving..."
  mv $optwareFolder $optwareFolder-bak_`date +\%F_\%H-\%M`
fi

if [ -d $optwarearmFolder ] ; then
  echo -e "$WARNING Found optware.ng.arm installation, saving..."
  mv $optwarearmFolder $optwarearmFolder-bak_`date +\%F_\%H-\%M`
fi

echo -e "$INFO Creating $entFolder folder..."
mkdir $entFolder

if [ -d /tmp/opt ] ; then
  echo -e "$WARNING Deleting old /tmp/opt symlink..."
  rm /tmp/opt
fi

echo -e "$INFO Creating /tmp/opt symlink..."
ln -sf $entFolder /tmp/opt

echo -e "$INFO Creating /jffs scripts backup..."
tar -czf $entPartition/jffs_scripts_backup_`date +\%F_\%H-\%M`.tgz /jffs/scripts/* >/dev/nul

echo -e "$INFO Modifying start scripts..."
cat > /jffs/scripts/services-start << EOF
#!/bin/sh

RC='/opt/etc/init.d/rc.unslung'

i=30
until [ -x "\$RC" ] ; do
  i=\$((\$i-1))
  if [ "\$i" -lt 1 ] ; then
    logger "Could not start Entware-NG"
    exit
  fi
  sleep 5
done
\$RC start
EOF
chmod +x /jffs/scripts/services-start

cat > /jffs/scripts/services-stop << EOF
#!/bin/sh

/opt/etc/init.d/rc.unslung stop
EOF
chmod +x /jffs/scripts/services-stop

cat > /jffs/scripts/post-mount << EOF
#!/bin/sh

if [ "\$1" = "__Partition__" ] ; then
  ln -nsf \$1/$ENT_FOLD /tmp/opt
fi

sleep 2
if [ -f /opt/swap ]
then
  echo -e "Mounting swap file..."
  swapon /opt/swap
else
  echo -e "Swap file not found or /opt is not mounted..."
fi
EOF
eval sed -i 's,__Partition__,$entPartition,g' /jffs/scripts/post-mount
chmod +x /jffs/scripts/post-mount

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
    echo Router model `cat "/proc/sys/kernel/hostname"`
    echo "---------"
    echo "SWAP FILE"
    echo "---------"
    echo "Choose swap file size (Highly Recommended)"
    echo "1. 512MB"
    echo "2. 1024MB"
    echo "3. 2048MB (recommended for MySQL Server or PlexMediaServer)"	
    echo "4. Skip this step, I already have a swap file / partition"
    echo "   or I don't want to create one right now"
    read -p "Enter your choice [ 1 - 4 ] " choice
    case $choice in
        1) 
            echo -e "$INFO Creating a 512MB swap file..."
            echo -e "$INFO This could take a while, be patient..."
            dd if=/dev/zero of=/opt/swap bs=1024 count=524288
            mkswap /opt/swap
            chmod 0600 /opt/swap
			swapon /opt/swap
            read -p "Press [Enter] key to continue..." readEnterKey
			break
            ;;
        2)
            echo -e "$INFO Creating a 1024MB swap file..."
            echo -e "$INFO This could take a while, be patient..."
            dd if=/dev/zero of=/opt/swap bs=1024 count=1048576
            mkswap /opt/swap
            chmod 0600 /opt/swap
			swapon /opt/swap
            read -p "Press [Enter] key to continue..." readEnterKey
			break
            ;;
        3)
            echo -e "$INFO Creating a 2048MB swap file..."
            echo -e "$INFO This could take a while, be patient..."
            dd if=/dev/zero of=/opt/swap bs=1024 count=2097152
            mkswap /opt/swap
            chmod 0600 /opt/swap
			swapon /opt/swap
            read -p "Press [Enter] key to continue..." readEnterKey
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
            read -p "Press [Enter] key to continue..." readEnterKey
            ;;
    esac	
done

cat > /opt/bin/services << EOF
#!/bin/sh

export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin$PATH

case "\$1" in
 start)
   sh /jffs/scripts/services-start
   ;;
 stop)
   sh /jffs/scripts/services-stop
   ;;
 restart)
   sh /jffs/scripts/services-stop
   echo -e Restarting Entware-NG Installed Services...
   sleep 2
   sh /jffs/scripts/services-start
   ;;
 *)
   echo "Usage: services {start|stop|restart}" >&2
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
