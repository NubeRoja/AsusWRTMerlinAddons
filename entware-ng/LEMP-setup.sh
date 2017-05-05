#!/bin/sh
BOLD="\033[1m"
NORM="\033[0m"
INFO="${BOLD}Info: $NORM"
WARNING="${BOLD}* Warning: $NORM"
INPUT="${BOLD}=> $NORM"

getgithubraw () {
	[ -f "$2" ] && mv "$2" "$2-opkg"
	wget -O "$2" "https://raw.githubusercontent.com/NubeRoja/AsusWRTMerlinAddons/master$2"
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
echo -e "${INFO}Php5-fpm the FastCGI Process Manager of the PHP5 interpreter,"
echo -e "${INFO}and mysql-server the database engine."
echo -e "${INFO}Additionally phpMyAdmin will be installed in www.yourdomain.com/phpmyadmin"
echo -e "${INFO}If nginx, php, php5-fpm and mysql-server are already installed,"
echo -e "${INFO}the script will copy old config files to 'name'.PRELEMP"
echo -en "${INPUT} Where do you want to install web server archives? [/opt/share/www] "
read wwwdir
if [ -z "$wwwdir" ]; then wwwdir="/opt/share/www"; fi
nginxINST=$(opkg list-installed | awk '{print $1}' | grep -q "nginx" && echo true || echo false)
phpINSTt=$(opkg list-installed | awk '{print $1}' | grep -q "php5" && echo true || echo false)
phpfpmINST=$(opkg list-installed | awk '{print $1}' | grep -q "php5-fpm" && echo true || echo false)
mysqlINST=$(opkg list-installed | awk '{print $1}' | grep -q "mysql-server" && echo true || echo false)

if $nginxINST; then
	echo -e "${WARNING}Nginx already installed, saving '/opt/etc/nginx/nginx.conf-PRELEMP' & '/opt/etc/nginx/sites-available-PRELEMP'"
	[ -f /opt/etc/nginx/nginx.conf ] && cp /opt/etc/nginx/nginx.conf /opt/etc/nginx/nginx.conf-PRELEMP
	[ -d /opt/etc/nginx/sites-available ] && mv /opt/etc/nginx/sites-available /opt/etc/nginx/sites-available-PRELEMP
	[ -d /opt/etc/nginx/sites-enabled ] && rm -r /opt/etc/nginx/sites-enabled
fi

if $phpfpmINST; then
	echo -e "${WARNING}php5-fpm already installed, saving '/opt/etc/php5-fpm.d-PRELEMP/'"
	[ -f /opt/etc/php5-fpm.d/www.conf ] && mv /opt/etc/php5-fpm.d/ /opt/etc/php5-fpm.d-PRELEMP/ && mkdir -p /opt/etc/php5-fpm.d/
fi

if $phpINSTt; then
	echo -e "${WARNING}php5 already installed, saving '/opt/etc/php.ini-PRELEMP'"
	[ -f /opt/etc/php.ini ] && cp /opt/etc/php.ini /opt/etc/php.ini.PRELEMP
fi

if $mysqlINST; then
	echo -e "${WARNING}MySQL Server already installed, saving '/opt/etc/my.cnf.PRELEMP'"
	[ -f /opt/etc/my.cnf ] && cp /opt/etc/my.cnf /opt/etc/my.cnf.PRELEMP
fi

opkg install nginx && echo -e "${INFO}Nginx installed Ok, configuring..."
getgithubraw "/entware-ng/LEMP-config/nginx.conf" "/opt/etc/nginx.conf"
mkdir -p "/opt/etc/nginx/sites-available"
mkdir -p "/opt/etc/nginx/sites-enabled"
getgithubraw "/entware-ng/LEMP-config/default" "/opt/etc/nginx/sites-available/default"
cd /opt/etc/nginx/sites-enabled
ln -sf ../sites-available/default default
getgithubraw "/entware-ng/LEMP-config/S80nginx" "/opt/etc/init.d/S80nginx"
chmod 755 /opt/etc/init.d/S80nginx
[ -f /opt/etc/init.d/S80nginx-opkg ] && chmod 555 /opt/etc/init.d/S80nginx-opkg

opkg install php5-fpm && echo -e "${INFO}php5-fpm installed Ok, configuring..."
getgithubraw "/entware-ng/LEMP-config/php.ini" "/opt/etc/php.ini"
mkdir -p /opt/tmp/php
chmod 755 /opt/tmp/php
getgithubraw "/entware-ng/LEMP-config/www.conf" "/opt/etc/php5-fpm.d/www.conf"

opkg install mysql-server && echo -e "${INFO}mysql-server installed Ok, configuring..."
getgithubraw "/entware-ng/LEMP-config/my.cnf" "/opt/etc/my.cnf"
opkg install php5-mod-mysqli php5-mod-session php5-mod-mbstring php5-mod-json
mysql_install_db --force

mkdir -p $wwwdir
cd $wwwdir
cat > $wwwdir/info.php << EOF
<?php
phpinfo();
?>
EOF

mv /opt/share/nginx/html/* $wwwdir
rm -r /opt/share/nginx

cd $wwwdir
wget https://files.phpmyadmin.net/phpMyAdmin/4.0.10.15/phpMyAdmin-4.0.10.15-all-languages.zip --no-check-certificate
unzip -q phpMyAdmin-4.0.10.15-all-languages.zip
mv ./phpMyAdmin-4.0.10.15-all-languages ./phpmyadmin
rm ./phpMyAdmin-4.0.10.15-all-languages.zip

cp $wwwdir/phpmyadmin/config.sample.inc.php $wwwdir/phpmyadmin/config.inc.php
chmod 644 $wwwdir/phpmyadmin/config.inc.php
sed -i 's/localhost/127.0.0.1/g' "$wwwdir/phpmyadmin/config.inc.php"

services restart
