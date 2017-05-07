# Entware-ng installation scrtips
Scripts and config-files for Asuswrt-Merlin & entware-ng.

Although these files are mostly for my own personal use, in case any of them are of interest for other users please feel free to take what you need. Feedback is also welcome.

## Installation
Download script to your device and execute it.
The script will install the packages required, backup original opkg config files that will be modified by the script and donwload modified files from the /opt dir
* Asus WRT-Merlin:  http://asuswrt.lostrealm.ca/
* Entware-ng: https://www.hqt.ro/how-to-install-new-generation-entware/

## Scripts
### LEMP-setup
From wikipedia:
LEMP is an archetypal model of web service stacks, named as an acronym of the names of its original four open-source components: the Linux operating system, the Apache HTTP Server, the MySQL relational database management system (RDBMS), and the PHP programming language. The LAMP components are largely interchangeable and not limited to the original selection. As a solution stack, LAMP is suitable for building dynamic web sites and web applications.
This script will install nginx, php5-fpm and mysql-server.
Modified config and custom files are: 
* /opt/etc/nginx/nginx.conf. Backup original at /opt/etc/nginx/nginx.conf-opkg
* /opt/etc/nginx/sites-available/default
* /opt/etc/php5-fpm.d/www.conf. Backup original at /opt/etc/php5-fpm.d-opkg/www.conf
* /opt/etc/php.ini. Backup original at /opt/etc/php.ini-opkg
* /opt/etc/my.cnf. Backup original at /opt/etc/php.ini-opkg

## Tips and tricks
If you like it but want to change some options in config files:
* Fork it
* Change /opt config files
* Edit github url source in setup scripts for download your modified configs, this source is hardcoded in getgithubraw fuction, i.e. https://raw.githubusercontent.com/NubeRoja/AsusWRTMerlinAddons/master/entware-ng
