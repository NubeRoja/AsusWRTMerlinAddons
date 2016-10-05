#!/opt/bin/bash
SERVER=myServer
source /opt/etc/profile
(sleep 60; /opt/bin/ntpdate $myServer &> /opt/result_ntpdate ) &
