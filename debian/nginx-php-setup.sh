#!/bin/sh
chroot /opt/debian/ apt install bzip2 nginx php5 php5-fpm
cat > /opt/debian/etc/nginx/sites-available/default << EOF
server {
	listen 82;
	#listen [::]:82 default_server ipv6only=on; ## listen for ipv6

	root /usr/share/nginx/html;
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

sed -i 's/memory_limit = 128M/memory_limit = 16M/g' "/opt/debian/etc/php5/fpm/php.ini"

cat > /opt/debian/usr/share/nginx/html/info.php << EOF
<?php
phpinfo();
?>
EOF

chroot /opt/debian/ service php5-fpm restart
chroot /opt/debian/ service nginx restart

echo "nginx" >>/opt/etc/chroot-services.list
echo "php5-fpm" >>/opt/etc/chroot-services.list

debian restart
