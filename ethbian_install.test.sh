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

echo 'Checking if ethbian-geth-upgrade.sh file exists: '
if [ -x /usr/local/sbin/ethbian-geth-upgrade.sh ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if influxdb.conf file exists: '
if [ -f /etc/influxdb/influxdb.conf ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if influxdb.conf.org file exists: '
if [ -f /etc/influxdb/influxdb.conf.org ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking GOMAXPROCS for influxdb: '
CMD=`grep GOMAXPROCS /etc/default/influxdb`
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if influxdb service is enabled: '
systemctl is-enabled --quiet influxdb
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi

echo 'Checking if collectd.conf file exists: '
if [ -f /etc/collectd/collectd.conf ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if collectd.conf.org file exists: '
if [ -f /etc/collectd/collectd.conf.org ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if /usr/local/lib/collectd directory exists: '
if [ -d /usr/local/lib/collectd ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if /usr/local/lib/collectd/rpi_temperature.py file exists: '
if [ -f /usr/local/lib/collectd/rpi_temperature.py ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if /usr/local/lib/collectd/geth_status.py file exists: '
if [ -f /usr/local/lib/collectd/geth_status.py ]; then
    echo '          [OK]'
else
    echo '          [ERROR]'
fi

echo 'Checking if inflcollectd service is enabled: '
systemctl is-enabled --quiet collectd
if [ $? -ne 0 ]; then
    echo '          [ERROR]'
else
    echo '          [OK]'
fi
