#!/bin/sh
opkg install nginx php5-fpm

mkdir -p /opt/etc/nginx/sites-available
mkdir -p /opt/etc/nginx/sites-enabled

cat > /opt/etc/nginx/sites-available/default << EOF
server {
	listen 80;
	#listen [::]:82 default_server ipv6only=on; ## listen for ipv6

	root /opt/var/www;
	index index.html index.htm;

	# Make site accessible from http://localhost/
	server_name localhost;
	# pass the PHP scripts to FastCGI server listening on /var/run/php5-fpm.sock
	location ~ .php\$ {
		try_files \$uri =404;
		fastcgi_pass unix:/var/run/php5-fpm.sock;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		include fastcgi_params;
	}

	location /doc/ {
		alias /usr/share/doc/;
		autoindex on;
		allow 127.0.0.1;
		allow ::1;
		deny all;
	} 
}
EOF

ln -sf /opt/etc/nginx/sites-available/default /opt/etc/nginx/sites-enabled/default

sed -i 's/memory_limit = 128M/memory_limit = 16M/g' "/opt/etc/php.ini"

cat > /opt/var/www/info.php << EOF
<?php
phpinfo();
?>
EOF
sed -i 's_;listen = /var/run/php5-fpm.sock_listen = /var/run/php5-fpm.sock_g' "/opt/etc/php5-fpm.d/www.conf"
sed -i 's_listen = 127.0.0.1:9000_;listen = 127.0.0.1:9000_g' "/opt/etc/php5-fpm.d/www.conf"

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

services restart
