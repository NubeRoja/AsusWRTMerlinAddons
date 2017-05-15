#!/bin/sh
BOLD="\033[1m"
NORM="\033[0m"
INFO="${BOLD}Info: $NORM"
WARNING="${BOLD}* Warning: $NORM"
INPUT="${BOLD}=> $NORM"
getgithubraw () {
	[ -f "$1" ] && mv "$1" "$1-opkg"
	wget -O "$1" "https://raw.githubusercontent.com/NubeRoja/AsusWRTMerlinAddons/master/entware-ng$1"
	[ ! -z "$2" ] && chmod "$2" "$1"
}

clear
echo -e "${INFO}This script was created by NubeRoja."
echo -e "${INFO}But is based on tutorials around the internet"
echo -e "${INFO}And this excellent forum https://www.snbforums.com/"
echo -e "${INFO}Thanks @zyxmon \& @ryzhov_al for New Generation Entware"
echo -e "${INFO}and @Rmerlin for his awesome firmwares"
sleep 2
echo -e "${INFO}This script will guide you through a logrotate installation."
echo -e "${INFO}The installation is very simple, "
echo -e "${INFO}but it will ask for configure logrotate to rotate LEMP logs"
sleep 2
echo
while :
do
	echo -en "${INPUT} Do you want to rotate nginx logs? (y/n) "
	read yesno
	case $yesno in
		y|Y)
			nginxrotate=true
			break
			;;
		n|N)
			nginxrotate=false
			break
			;;
		*)
			echo "type only y/n"
			;;
	esac		
done
while :
do
	echo -en "${INPUT} Do you want to rotate php5-fpm logs? (y/n) "
	read yesno
	case $yesno in
		y|Y)
			php5fpmrotate=true
			break
			;;
		n|N)
			php5fpmrotate=false
			break
			;;
		*)
			echo "type only y/n"
			;;
	esac		
done
while :
do
	echo -en "${INPUT} Do you want to rotate mysql logs? (y/n) "
	read yesno
	case $yesno in
		y|Y)
			mysqlrotate=true
			break
			;;
		n|N)
			mysqlrotate=false
			break
			;;
		*)
			echo "type only y/n"
			;;
	esac		
done
opkg install logrotate
[ nginxrotate ] && getgithubraw "/opt/etc/logrotate.d/nginx" 644
[ php5fpmrotate ] && getgithubraw "/opt/etc/logrotate.d/php5-fpm" 644
[ mysqlrotate ] && getgithubraw "/opt/etc/logrotate.d/mysql" 644 && getgithubraw "/jffs/home/root/.my.cnf" 600
if [ ! -f /jffs/scripts/services-start ]; then
	echo "#!/bin/sh/" > "/jffs/scripts/services-start"
	echo "TAG=\"\$(basename \"\$0\") \$*\"" >> "/jffs/scripts/services-start"
	chmod 755 "/jffs/scripts/services-start"
fi
echo "ln -sf /jffs/home/root/.my.cnf /tmp/home/root/.my.cnf" >> "/jffs/scripts/services-start"
echo "cru a logrotate \"0 5 * * * /opt/sbin/logrotate /opt/etc/logrotate.conf\"" >> "/jffs/scripts/services-start"
echo "logger -t \"\$TAG\" \"Created Logrotate cron job\"" >> "/jffs/scripts/services-start"


