#!/bin/sh
BOLD="\033[1m"
NORM="\033[0m"
INFO="${BOLD}Info: $NORM"
ERROR="${BOLD}*** Error: $NORM"
WARNING="${BOLD}* Warning: $NORM"
INPUT="${BOLD}=> $NORM"

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
echo -e "${INPUT} Where do you want to install web server archives? [/opt/share/www] "
read wwwdir
[[ -z "$wwwdir" ]] && wwwdir="/opt/share/www"
nginxINSt=$(opkg list-installed | awk '{print $1}' | grep -q "nginx" && echo true || echo false)

if $nginxINST; then
	[ -f /opt/etc/nginx/nginx.conf ] && mv /opt/etc/nginx/nginx.conf /opt/etc/nginx/nginx.conf.PRE-LEMP
	if [ -d /opt/etc/nginx/sites-available ]; then
		mv /opt/etc/nginx/sites-available /opt/etc/nginx/sites-available.PRE-LEMP
	else
		mkdir -p /opt/etc/nginx/sites-available
	fi
	if [ -d /opt/etc/nginx/sites-enabled ]; then
		rm /opt/etc/nginx/sites-enabled/*
	else
		mkdir -p /opt/etc/nginx/sites-enabled
	fi
else
	mkdir -p /opt/etc/nginx/sites-available
	mkdir -p /opt/etc/nginx/sites-enabled
fi

opkg install nginx --force-reinstall

cat > /opt/etc/nginx/nginx.conf << EOF
user  nobody nobody;
worker_processes  1;

#error_log  /opt/var/log/nginx/error.log;
#error_log  /opt/var/log/nginx/error.log  notice;
#error_log  /opt/var/log/nginx/error.log  info;

#pid        /opt/var/run/nginx.pid;

events {
        worker_connections  1024;
}

http {
        include       mime.types;
        default_type  text/html;

        #log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
        #                  '\$status \$body_bytes_sent "\$http_referer" '
        #                  '"\$http_user_agent" "\$http_x_forwarded_for"';

        #access_log  /opt/var/log/nginx/access.log main;

        server_names_hash_bucket_size 64;

        sendfile        on;
        #tcp_nopush     on;

        #keepalive_timeout  0;
        keepalive_timeout  65;

        gzip  on;
        gzip_min_length  1k;
        gzip_buffers     4 16k;
        gzip_http_version 1.0;
        gzip_comp_level 2;
        gzip_types       text/plain application/x-javascript text/css application/xml;
        gzip_vary on;

        include /opt/etc/nginx/sites-enabled/*;
}
EOF

cat > /opt/etc/nginx/sites-available/default << EOF
server {
        listen 80;
        server_name calambre.local www.calambre.local;

        root $wwwdir;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ /404.html;

        proxy_buffers 16 16k;
        proxy_buffer_size 16k;
        client_body_timeout 10;
        client_header_timeout 10;
        send_timeout 60;                # 60 sec should be enough, if experiencing a lot of timeouts, increase this.
        output_buffers 1 32k;
        postpone_output 1460;

        location = /favicon.ico {
                log_not_found off;
                access_log off;
        }

        location = /robots.txt {
                allow all;
                log_not_found off;
                access_log off;
        }

        location ~ /\\. {
                deny all;
                access_log off;
                log_not_found off;
        }

        location ~*  \\.(jpg|jpeg|png|gif|css|js|ico)\$ {
                expires max;
                log_not_found off;
        }

        location ~ \\.php\$ {
                fastcgi_connect_timeout 300;
                fastcgi_send_timeout 300;
                fastcgi_read_timeout 300;
                fastcgi_buffer_size 32k;
                fastcgi_buffers 4 32k;
                fastcgi_busy_buffers_size 32k;
                fastcgi_temp_file_write_size 32k;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include       fastcgi_params;
        }
}
EOF
cd /opt/etc/nginx/sites-enabled
ln -sf ../sites-available/default default

cat > /opt/etc/init.d/S80nginx << EOF
#!/bin/sh
ansi_red="\033[1;31m";
ansi_white="\033[1;37m";
ansi_green="\033[1;32m";
ansi_std="\033[m";
ENABLED=yes
PROCS=nginx
PREARGS=""
DESC=Nginx

PATH=/opt/sbin:/opt/bin:/opt/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

case \$1 in
	start)
		ARGS=""
		. /opt/etc/init.d/rc.func
		;;
	stop | kill)
		ARGS="-s quit"
		. /opt/etc/init.d/rc.func
		;;
	restart)
		ARGS="-s quit"
		. /opt/etc/init.d/rc.func stop
		ARGS=""
		. /opt/etc/init.d/rc.func start
		;;
	check)
		ARGS=""
		. /opt/etc/init.d/rc.func
		;;
	reload)
		echo -e -n "\$ansi_white Reloading Nginx conf...       "
		nginx -s reload && echo -e "\$ansi_green done." || echo -e "\$ansi_red failed.\$ansi_std"
		;;
		reopen)
		echo -e -n "\$ansi_white Reopening Nginx log files...  "
		nginx -s reopen && echo -e "\$ansi_green done." || echo -e "\$ansi_red failed.\$ansi_std"
		;;
	test)
		nginx -t
		;;
	*)
		echo -e "\$ansi_white Usage: \$0 (start|stop|restart|check|kill|reload|reopen|test)\$ansi_std"
		;;
esac
EOF
chmod 755 /opt/etc/init.d/S80nginx

php5INSTt=$(opkg list-installed | awk '{print $1}' | grep -q "php5" && echo true || echo false)

if $php5INSTt; then
	[ -f /opt/etc/php.ini ] && mv /opt/etc/php.ini /opt/etc/php.ini.PRE-LEMP
	opkg remove php5
fi

php5-fpmINST=$(opkg list-installed | awk '{print $1}' | grep -q "php5-fpm" && echo true || echo false)

if $php5-fpmINST; then
	[ -f /opt/etc/php5-fpm.d/www.conf ] && mv /opt/etc/php5-fpm.d/ /opt/etc/php5-fpm.d.PRE-LEMP/
fi

opkg install php5-fpm --force-reinstall
opkg install php5-mod-mysqli
#sed -i 's_doc_root =  "$wwwdir"_doc_root = "$wwwdir"_g' "/opt/etc/php.ini"

sed -i 's_;listen = /var/run/php5-fpm.sock_listen = /var/run/php5-fpm.sock_g' "/opt/etc/php5-fpm.d/www.conf"
sed -i 's_listen = 127.0.0.1:9000_;listen = 127.0.0.1:9000_g' "/opt/etc/php5-fpm.d/www.conf"
sed -i 's_;listen.owner = www-data_listen.owner = nobody_g' "/opt/etc/php5-fpm.d/www.conf"
sed -i 's_;listen.group = www-data_listen.group = nobody_g' "/opt/etc/php5-fpm.d/www.conf"

mysqlINST=$(opkg list-installed | awk '{print $1}' | grep -q "mysql-server" && echo true || echo false)

if $mysqlINST; then
	[ -f /opt/etc/my.cnf ] && mv /opt/etc/my.cnf /opt/etc/my.cnf.PRE-LEMP
fi

opkg install mysql-server -force-reinstall

sed -E -i 's_socket[[:space:]]+= /opt/var/run/mysqld.sock_socket          = /var/run/mysqld.sock_g' "/opt/etc/my.cnf"
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
unzip phpMyAdmin-4.0.10.15-all-languages.zip
mv ./phpMyAdmin-4.0.10.15-all-languages ./phpmyadmin
rm ./phpMyAdmin-4.0.10.15-all-languages.zip

cp $wwwdir/phpmyadmin/config.sample.inc.php $wwwdir/phpmyadmin/config.inc.php
chmod 644 $wwwdir/phpmyadmin/config.inc.php
sed -i 's/localhost/127.0.0.1/g' "$wwwdir/phpmyadmin/config.inc.php"


services restart
