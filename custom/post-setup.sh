#!/bin/sh
cat > /jffs/configs/profile.add << EOF
export PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] '
alias ls='ls --color=yes'
alias l='ls -lFA --color=yes'
alias ll='ls -lF --color=yes'
alias cd..='cd ..'
EOF
echo "profile.add ok"

mkdir -p /jffs/etc/
cat > /jffs/etc/ntp.conf << EOF
server 1.es.pool.ntp.org
server 3.europe.pool.ntp.org
server 2.europe.pool.ntp.org
EOF
echo "ntp.conf ok"

cat > /jffs/scripts/services-start << EOF
#!/bin/sh
ln -sf /jffs/etc/ntp.conf /tmp/etc/ntp.conf
if [ \$(nvram get ntp_ready) -eq 1 ]; then
	ntpd -l
else
	logger -t "\$(basename \$0) \$*" "Cannot get initialise NTP Server!"
fi
EOF
chmod +x /jffs/scripts/services-start
echo "services-start ok"

cat > /jffs/scripts/dnsmasq.postconf << EOF
#!/bin/sh
sed -i "s/ppp1/ppp0/g" \$1
EOF
chmod +x /jffs/scripts/dnsmasq.postconf
echo "dnsmasq.postconf ok"
