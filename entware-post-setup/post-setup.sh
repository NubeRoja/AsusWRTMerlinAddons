#!/opt/bin/bash
echo "[ -f /opt/bin/bash ] && exec /opt/bin/bash" >> /jffs/configs/profile.add
cp dot_bashrc dot_bash_profile dot_inputrc dot_gitconfig /jffs/

FILE="/jffs/scripts/init-start"
ROOT="/tmp/home/root"

/bin/cat <<EOF >$FILE
#!/bin/sh
# Prepare for backupmounting
mkdir /mnt/RemoteBackupMount
touch /mnt/RemoteBackupMount/unmounted
echo 'agent007:/Backups /mnt/RemoteBackupMount nfs defaults,noauto' >> /etc/fstab
# Add Bash-profile stuff
ln -s /jffs/dot_gitconfig $ROOT/.gitconfig
ln -s /jffs/dot_bashrc $ROOT/.bashrc
ln -s /jffs/dot_bash_profile $ROOT/.bash_profile
ln -s /jffs/dot_inputrc $ROOT/.inputrc
touch /jffs/dot_bash_history
ln -s /jffs/dot_bash_history $ROOT/.bash_history
# Add rule for backup every monday (day 1, 05 h)
# Format is <minute hour day month weekday cmd>
/usr/sbin/cru a 091875 0 05 '*' '*' 1 /mnt/BackupDisk/bin/backup_script.sh
EOF
chmod a+x $FILE
