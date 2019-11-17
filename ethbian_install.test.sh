#!/bin/bash

echo ""
echo "*****************************************"
echo "*       ETHBIAN INSTALL TEST v0.1       *"
echo "*****************************************"
echo ""
echo "*RR - requires reboot"
echo ""

echo 'Checking if user eth exists: '
CMD=`id eth > /dev/null 2>&1`
RESPONSE=$?
if [ $RESPONSE -eq 0 ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if temp script exists: '
if [ -x /usr/local/bin/temp ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if gat script exists: '
if [ -x /usr/local/bin/gat ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if dphys-swapfile package was removed: '
CMD=`dpkg -l |grep dphys-swapfile|wc -l`
if [ $CMD -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if swap is disabled (*RR): '
CMD=`swapon -s |wc -w`
if [ $CMD -eq 0 ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if wpa_supplicant is disabled: '
if [ -L /etc/systemd/system/multi-user.target.wants/wpa_supplicant.service ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if open files limit is increased (*RR): '
CMD=`ulimit -a |grep 'open files' |grep -c 32000`
if [ $CMD -eq 1 ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if IPv6 is disabled (*RR): '
CMD=`ifconfig |grep -c inet6`
if [ $CMD -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi


echo ""
echo 'Checking if wifi is disabled: '
CMD=`iw dev |grep -c Interface`
if [ $CMD -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if bluetooth is disabled: '
CMD=`hciconfig |wc -l`
if [ $CMD -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if sound card is disabled: '
CMD=`aplay -l 2>/dev/null|wc -l`
if [ $CMD -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if camera modules are disabled: '
CMD=`lsmod |grep -c bcm2835`
if [ $CMD -eq 0 ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo ""
echo 'Checking if geth is installed: '
if [ -x /usr/local/bin/geth/geth ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if geth service file exists: '
if [ -f /lib/systemd/system/geth.service ]; then
    echo -n '          [OK] '
else
    echo -n '          [ERROR] '
fi
if [ -L /etc/systemd/system/geth.service ]; then
    echo ' [OK]'
else
    echo ' [ERROR]'
fi

echo 'Checking syslog for geth: '
CMD=`grep -c geth /etc/rsyslog.conf`
if [ $CMD -ne 2 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking logrotate for geth: '
CMD=`grep geth /etc/logrotate.d/geth`
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo ""
echo 'Checking if html directory exists: '
if [ -d /var/www/html ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if index.html file exists: '
if [ -f /var/www/html/index.html ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking main.css file: '
CMD=`grep table /var/www/html/main.css`
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking webfs configuration: '
CMD=`grep ^web_index /etc/webfsd.conf |grep -c index.html`
if [ $CMD -ne 1 ]; then
    echo -n '          [ERROR] '
else
    echo -n '          [OK] '
fi
CMD=`grep ^web_extras /etc/webfsd.conf |grep -c eth`
if [ $CMD -ne 1 ]; then
    echo ' [ERROR]'
else
    echo ' [OK]'
fi

echo 'Checking sudo configuration: '
CMD=`sudo grep -c 'eth ALL=(ALL) NOPASSWD:/opt/vc/bin/vcgencmd measure_temp' /etc/sudoers`
if [ $CMD -ne 1 ]; then
    echo -n '          [ERROR] '
else
    echo -n '          [OK] '
fi
CMD=`sudo grep -c 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/syslog' /etc/sudoers`
if [ $CMD -ne 1 ]; then
    echo -n ' [ERROR] '
else
    echo -n ' [OK] '
fi
CMD=`sudo grep -c 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/geth.log' /etc/sudoers`
if [ $CMD -ne 1 ]; then
    echo ' [ERROR]'
else
    echo ' [OK]'
fi

echo 'Checking crontab configuration: '
CMD=`sudo grep status2html /var/spool/cron/crontabs/eth`
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking status2html file: '
CMD=`grep index /home/eth/status2html-cron.sh`
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if ethbian-net.sh file exists: '
if [ -x /usr/local/sbin/ethbian-net.sh ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if ethbian-ssd-init.sh file exists: '
if [ -x /usr/local/sbin/ethbian-ssd-init.sh ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi
