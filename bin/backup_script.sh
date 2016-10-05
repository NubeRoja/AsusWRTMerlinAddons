#!/opt/bin/bash
DATE=$(date +%Y-%m-%d-%H-%M-%S)

BACKUPDIR=/mnt/BackupDisk/Backup/Agent007-Snapshots
MOUNTDIR=/mnt/RemoteBackupMount
SRCDIR=${MOUNTDIR}/Agent007RsyncSnapshot
MOUNT_CHECK_FILE=Agent007RsyncSnapshot

RSYNC="rsync"
EXTRAOPTIONS="-v --delete"

writeToLog=true
pretend=false
while getopts vp opt
do	case "$opt" in
	v)	writeToLog=false;;
	p)	pretend=true;;
	[?])	echo  >&2 "Usage: $0 [-v] ..."
		exit 1;;
	esac
done

if  $writeToLog ; then
	echo "Using log-file: $BACKUPDIR/$DATE.log"
	exec 1>$BACKUPDIR/$DATE.log
fi

echo ""
echo --------------- Weekly Backup ---------------


echo ""
echo Checking for source-mount
echo -------------------------
if [ -e "$MOUNTDIR/unmounted" ]
then
  echo "  $MOUNTDIR is not mounted...."
  echo "  ... trying to mount: $MOUNTDIR"
  mount $MOUNTDIR
  if [ -e "$MOUNTDIR/$MOUNT_CHECK_FILE" ]
  then
      echo "  ...success!"
  else
      echo "  ...failure!"
      exit -1
  fi
else
  echo "  $MOUNTDIR seems to be mounted...."
  echo "  ... making sure"
  if [ -e "$MOUNTDIR/$MOUNT_CHECK_FILE" ]
  then
      echo "  ...success!"
  else
      echo "  ...failure!"
      exit -1
  fi
fi


echo ""
echo Backing up $SRCDIR
echo --------------------------

echo $DATE 



currentDir=$(pwd)
cd $BACKUPDIR/current
linkDestDir=$(pwd -P)
cd $currentDir
echo $destDir

echo Would do: $RSYNC -a $EXTRAOPTIONS --link-dest=$linkDestDir $SRCDIR/ $BACKUPDIR/$DATE

if  $pretend ; then
    echo "Pretend-mode: Disabling rsync"
else
    $RSYNC -a $EXTRAOPTIONS --link-dest=$linkDestDir $SRCDIR/ $BACKUPDIR/$DATE
    rm $BACKUPDIR/current
    ln -s  $DATE $BACKUPDIR/current
    touch $BACKUPDIR/$DATE
fi

echo ""
echo Unmounting Source
echo -------------------------
if [ -e "$MOUNTDIR/$MOUNT_CHECK_FILE" ]
then
  echo "  $MOUNTDIR is mounted, unmounting..."
  umount $MOUNTDIR
  if [ -e "$MOUNTDIR/unmounted" ]
  then
      echo "  ...success!"
  else
      echo "  ...failure!"
      exit -1
  fi
fi

#cp backup_log.txt $BACKUPDIR/$DATE.log

