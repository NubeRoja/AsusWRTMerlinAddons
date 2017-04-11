# AsusWRTMerlinAddons
Addons and setup-files for Asuswrt-Merlin.

Although these files are mostly for my own personal use, in case any of them are of interest for other users please feel free to take what you need. Feedback is also welcome.

## Installation
Packages and instructions are available at 
* Asus WRT-Merlin:  http://asuswrt.lostrealm.ca/
* Entware-ng: https://www.hqt.ro/how-to-install-new-generation-entware/

### Notes
* Entware-install script in "contrib" have been cleaned and modificated. The most important changes are in /jffs/scripts.
* Instead of using classic services-start and services-stop i preffer pre-mount, post-mount and unmount scripts
* This is because i use swap partition instead of swap file and want to check filesystem on every boot prior to mount filesystem, but this solution is incompatible with some entware-ng packages
* See more here: https://github.com/RMerl/asuswrt-merlin/wiki/USB-Disk-Check-at-Boot

### Procedure 
  1. Install AsusWRT Merlin 
  2. Install entware-ng
  3. Install debian
  
### Extra packages 
A list of extra packages that should be installed using "opkg install" are:
* bash 
* bzip2 
* git 
* git-http 
* nano 
* rsync 
* tar 



## Tips and tricks
Some tips and tricks for stuff that may go wrong
* Turn on NFS-server without enabling any shares to get NFS-client support
