# Entware-ng installation scripts
Scripts and config-files for Asuswrt-Merlin & entware-ng. 

This site was created to help me with a quick and clean installation of the software that I currently run on my asus RT-AC56U router. My knowledge of linux is limited and I also have bad memory, so installing software on my router and making it work properly takes me too long to find information available in forums, tutorials, etc. and testing on my router.

Although these files are mostly for my own personal use, in case any of them are of interest for other users please feel free to take what you need. Feedback is also welcome.

* Asus WRT-Merlin:  http://asuswrt.lostrealm.ca/
* Entware-ng: https://www.hqt.ro/how-to-install-new-generation-entware/
* Special thanks to TeHashX and his excellent site https://www.hqt.ro/

## Installation
Download raw script to your device, make it executable and execute it. i.e.

The script will:
* Install the entware-ng packages required.
* Backup original opkg config files that will be modified by the script
* Donwload modified files from the /opt dir

## Scripts
### LEMP-setup
From wikipedia:
LAMP is an archetypal model of web service stacks, named as an acronym of the names of its original four open-source components:
* The Linux operating system
* The Apache HTTP Server
* The MySQL relational database management system (RDBMS)
* The PHP programming language.

The LAMP components are largely interchangeable and not limited to the original selection. As a solution stack, LAMP is suitable for building dynamic web sites and web applications. In this case Apache http server is substituted with nginx "enginex" and therefore LAMP becomes LEMP

<code>cd /tmp && wget https://raw.githubusercontent.com/NubeRoja/AsusWRTMerlinAddons/master/entware-ng/LEMP-setup.sh && chmod +x LEMP-setup.sh && ./LEMP-setup.sh</code>

This script will install nginx, php5-fpm and mysql-server and phpmyadmin. I use it 
Modified config and custom files are: 
* /opt/etc/nginx/nginx.conf. Backup original at /opt/etc/nginx/nginx.conf-opkg
* /opt/etc/nginx/sites-available/default
* /opt/etc/php5-fpm.d/www.conf. Backup original at /opt/etc/php5-fpm.d-opkg/www.conf
* /opt/etc/php.ini. Backup original at /opt/etc/php.ini-opkg
* /opt/etc/my.cnf. Backup original at /opt/etc/php.ini-opkg

Uses that I give:
Kodi database synchronized across all my players
Proxy server of webcams, printers, etc. You need a dns server configured with your domain 

## Tips and tricks
You can execute diff in modified config files to view what is changed, i.e. diff /opt/etc/php.ini /opt/etc/php.ini-opkg

If you like it but want to change some options in config files:
* Fork it
* Change /opt config files
* Edit github url source in setup scripts for download your modified configs, this source is hardcoded in getgithubraw fuction, i.e. https://raw.githubusercontent.com/NubeRoja/AsusWRTMerlinAddons/master/entware-ng
