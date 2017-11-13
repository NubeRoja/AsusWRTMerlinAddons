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
echo -e "${INFO}And this excellent web by TeHashX."
echo -e "${INFO}https://www.hqt.ro/"
echo -e "${INFO}Thanks @zyxmon \& @ryzhov_al for New Generation Entware"
echo -e "${INFO}and @Rmerlin for his awesome firmwares"
sleep 2
echo -e "${INFO}This script will guide you through a LEMP installation."
echo -e "${INFO}Nginx will be the http server,"
echo -e "${INFO}Php7-fpm the FastCGI Process Manager of the PHP7 interpreter,"
echo -e "${INFO}and mysql-server the database engine."
echo -e "${INFO}Additionally phpMyAdmin will be installed in www.yourdomain.com/phpmyadmin"
echo -e "${INFO}If nginx, php, php7-fpm and mysql-server are already installed,"
echo -e "${INFO}the script will copy old config files to 'name'-PRELEMP"
sleep 2
echo
echo -en "${INPUT} Where do you want to install web server archives? [/opt/share/www] "
read wwwdir
echo -en "${INPUT} What is your domain name? [calambre.local] "
read domainname
while :
do
	echo -en "${INPUT} Need MySQL Server be available accross your lan? (y/n) "
	read yesno
	case $yesno in
		y|Y)
			mysqllocal=false
			break
			;;
		n|N)
			mysqllocal=true
			break
			;;
		*)
			echo "type only y/n"
			;;
	esac		
done
echo -en "${INPUT} Where do you want to install MySQl databases? [/opt/var/lib/mysql] "
read ddbbdir
while :
do
	echo -en "${INPUT} Type password for MySQL root user: "
	read -s mysqlpassword
	echo -en "${INPUT} Retype password: "
	read -s remysqlpassword
	[ "$mysqlpassword" = "$remysqlpassword" ] && break || echo -e "${WARNING}Password missmacth"
done

nginxINST=$(opkg list-installed | awk '{print $1}' | grep -q "nginx" && echo true || echo false)
phpINSTt=$(opkg list-installed | awk '{print $1}' | grep -q "php7" && echo true || echo false)
phpfpmINST=$(opkg list-installed | awk '{print $1}' | grep -q "php7-fpm" && echo true || echo false)
mysqlINST=$(opkg list-installed | awk '{print $1}' | grep -q "mysql-server" && echo true || echo false)

if $nginxINST; then
	echo -e "${WARNING}Nginx already installed, 'sites-enabled' will be erased"
	[ -d /opt/etc/nginx/sites-enabled ] && rm -r /opt/etc/nginx/sites-enabled
	if [ $(md5sum /opt/etc/nginx/nginx.conf  | awk '{print $1}') = "78aef7acee5ac134f0964979c6253905" ]; then
		echo -e "${INFO}Saving modified conffile '/opt/etc/nginx/nginx.conf-PRELEMP'"
		cp /opt/etc/nginx/nginx.conf /opt/etc/nginx/nginx.conf-PRELEMP
	fi
fi

if $phpfpmINST; then
	echo -e "${WARNING}php7-fpm already installed, saving '/opt/etc/php7-fpm.d/' 'files to /opt/etc/php7-fpm.d-PRELEMP/'"
	if [ $(md5sum /opt/etc/php7-fpm.d/www.conf  | awk '{print $1}') != "6f3c614aa969034320b37150d04980a0" ]; then
		echo -e "${INFO}Saving modified conffile '/opt/etc/php7-fpm.d-PRELEMP/'"
		mkdir -p /opt/etc/php7-fpm.d-PRELEMP/ && cp /opt/etc/php7-fpm.d/* /opt/etc/php7-fpm.d-PRELEMP/
	fi
	[ -d /opt/etc/php7-fpm.d/ ] && rm -r /opt/etc/php7-fpm.d
fi

if $phpINSTt; then
	echo -e "${WARNING}Php7 already installed"
	if [ $(md5sum /opt/etc/php.ini  | awk '{print $1}') != "76d25693b827cffcb6412ee230dc1515" ]; then
		echo -e "${INFO}Saving modified conffile '/opt/etc/php.ini-PRELEMP'"
		cp /opt/etc/php.ini /opt/etc/php.ini-PRELEMP
	fi
fi

if $mysqlINST; then
	echo -e "${WARNING}MySQL Server already installed, saving '/opt/etc/my.cnf-PRELEMP'"
	if [ $(md5sum /opt/etc/my.cnf  | awk '{print $1}') != "de13cdfc2bcc43a2d6f154fef88eca3a" ]; then
		echo -e "${INFO}Saving modified conffile '/opt/etc/my.cnf-PRELEMP'"
		cp /opt/etc/my.cnf /opt/etc/my.cnf-PRELEMP
	fi
fi

opkg install nginx --force-reinstall --forcemaintainer && echo -e "${INFO}Nginx installed Ok, configuring..."
mv /opt/etc/nginx/nginx.conf /opt/etc/nginx/nginx.conf-opkg
getgithubraw "/opt/etc/nginx/nginx.conf" 600
mkdir -p /opt/etc/nginx/sites-available
mkdir -p /opt/etc/nginx/sites-enabled
getgithubraw "/opt/etc/nginx/sites-available/default" 600
getgithubraw "/opt/etc/nginx/sites-available/proxypass" 600

if [ ! -z "$domainname" ]; then
	sed -i "s/calambre.local/$domainname/g" "/opt/etc/nginx/sites-available/default"
	sed -i "s/calambre.local/$domainname/g" "/opt/etc/nginx/sites-available/proxypass"
fi

cd /opt/etc/nginx/sites-enabled
ln -sf ../sites-available/default default
ln -sf ../sites-available/proxypass
mv /opt/etc/init.d/S80nginx /opt/etc/init.d/S80nginx-opkg && chmod 600 /opt/etc/init.d/S80nginx-opkg
getgithubraw "/opt/etc/init.d/S80nginx" 700

opkg install php7-fpm --force-reinstall --forcemaintainer && echo -e "${INFO}php7-fpm installed Ok, configuring..."
mv /opt/etc/php.ini /opt/etc/php.ini-opkg
getgithubraw "/opt/etc/php.ini" 600
mkdir -p /opt/tmp/php
chmod 777 /opt/tmp/php
cp -r /opt/etc/php7-fpm.d/ /opt/etc/php7-fpm.d-opkg/
getgithubraw "/opt/etc/php7-fpm.d/www.conf" 600
mv /opt/etc/init.d/S79php-fpm /opt/etc/init.d/S79php-fpm && chmod 600 /opt/etc/init.d/S79php-fpm-opkg
getgithubraw "/opt/etc/init.d/S79php-fpm" 700

if [ ! -z "$wwwdir" ]; then
	sed -i "s,/opt/share/www,$wwwdir,g" "/opt/etc/nginx/sites-available/default"
	sed -i "s,/opt/share/www,$wwwdir,g" "/opt/etc/php.ini"
else
	wwwdir=/opt/share/www
fi

mkdir -p /opt/tmp/mysql
mkdir -p /opt/var/lib/mysql
opkg install mysql-server --force-reinstall --forcemaintainer && echo -e "${INFO}mysql-server installed Ok, configuring..."
mv "/opt/etc/my.cnf" "/opt/etc/my.cnf-opkg"
getgithubraw "/opt/etc/my.cnf" 600
opkg install php7-mod-mysqli php7-mod-session php7-mod-mbstring php7-mod-json  --force-reinstall --forcemaintainer

[ $mysqllocal ] && sed -i 's/0.0.0.0/127.0.0.1/g' "/opt/etc/my.cnf"	
[ ! -z $ddbbdir ] && sed -iE "s,datadir[[:space:]]+= /opt/var/lib/mysql/,s,datadir		= $ddbbdir,g" "/opt/etc/my.cnf"
mysql_install_db --force
mysqladmin password $mysqlpassword

mkdir -p $wwwdir
cd $wwwdir
cat > $wwwdir/info.php << EOF
<?php
phpinfo();
?>
EOF

[ -d /opt/share/nginx/html/ ] && mv /opt/share/nginx/html/* $wwwdir && rm -r /opt/share/nginx

cd $wwwdir
wget https://files.phpmyadmin.net/phpMyAdmin/4.0.10.20/phpMyAdmin-4.0.10.20-all-languages.zip --no-check-certificate
unzip -q phpMyAdmin-4.0.10.20-all-languages.zip
mv ./phpMyAdmin-4.0.10.20-all-languages ./phpmyadmin
rm ./phpMyAdmin-4.0.10.20-all-languages.zip

cp $wwwdir/phpmyadmin/config.sample.inc.php $wwwdir/phpmyadmin/config.inc.php
chmod 644 $wwwdir/phpmyadmin/config.inc.php
sed -i 's/localhost/127.0.0.1/g' "$wwwdir/phpmyadmin/config.inc.php"

services restart
