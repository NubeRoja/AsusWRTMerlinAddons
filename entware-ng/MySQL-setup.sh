opkg install mysql-server php5-mod-mysql
mysql_install_db --force
/opt/etc/init.d/S70mysqld restart
cd /opt/share/www/
wget https://files.phpmyadmin.net/phpMyAdmin/4.0.10.15/phpMyAdmin-4.0.10.15-all-languages.zip --no-check-certificate
unzip phpMyAdmin-4.0.10.15-all-languages.zip
mv ./phpMyAdmin-4.0.10.15-all-languages ./phpmyadmin
rm ./phpMyAdmin-4.0.10.15-all-languages.zip
opkg install php5-mod-mbstring php5-mod-json php5-mod-session php5-mod-mysqli
cp /opt/share/www/phpmyadmin/config.sample.inc.php /opt/share/www/phpmyadmin/config.inc.php
chmod 644 /opt/share/www/phpmyadmin/config.inc.php
sed -i 's/localhost/127.0.0.1/g' "/opt/share/www/phpmyadmin/config.inc.php"
