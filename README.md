# AsusWRTMerlinAddons
Addons and setup-files for Asuswrt-Merlin.

Although these files are mostly for my own personal use, in case any of them are of interest for other users please feel free to take what you need. Feedback is also welcome.

## Installation
Packages and instructions are available at 
* Asus WRT-Merlin:  http://asuswrt.lostrealm.ca/
* Entware-ng: https://www.hqt.ro/how-to-install-new-generation-entware/

### Notes
* Entware-install script in "contrib" may be wildly outdated, above link should give instructions on how to get the latest version.
* 2Gb swap is not bad

### Procedure 
  1. Install AsusWRT Merlin 
  2. Install entware-ng
  3. Run post-setup.sh in ./entware-post-setup
  4. Try backupscript using -p for pretend  and -v for verbose to make sure mounts all work
  
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
