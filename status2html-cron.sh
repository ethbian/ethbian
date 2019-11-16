#!/bin/bash

# *****************************************
# *       ETHBIAN STATUS2HTML   v0.1      *
# *****************************************

TARGET=/var/www/html/index.html

NOW=`date +'%A, %T'`
UPTIME=`uptime -p`
DF_ROOT=`df -h /`
LOAD=`cat /proc/loadavg |cut -f -3 -d " "`
MEMORY=`free -m| grep -v Swap`

DF_SSD='NOT MOUNTED'
CMD=`mountpoint -q /mnt/ssd`
if [ $? -eq 0 ]; then
  DF_SSD=`df -h /mnt/ssd`
fi

TEMP=`sudo -n /opt/vc/bin/vcgencmd measure_temp`
if [ $? -ne 0 ]; then
  TEMP='NO DATA (or permissions)'
fi

GETH_STATUS=`systemctl --no-pager --output=cat status geth`

if [ -f /var/log/geth.log ]; then
  TAIL_GETH=`sudo /usr/bin/tail /var/log/geth.log |cut -f 1-3,8- -d " "|sed 's/ \+/ /g'`
else
  TAIL_GETH='NO DATA (or permissions)'
fi

TAIL_SYSLOG=`sudo -n /usr/bin/tail /var/log/syslog`
if [ $? -ne 0 ]; then
  TAIL_SYSLOG='NO DATA (or permissions)'
fi

GETH_SYNCING=""
GETH_NODEINFO=""
CMD=`pgrep geth`
if [ $? -eq 0 ]; then
  GETH_SYNCING=`/usr/local/bin/geth/geth attach --datadir=/mnt/ssd/datadir --exec eth.syncing |grep -Ev '{|}'`
  GETH_NODEINFO=`/usr/local/bin/geth/geth attach --datadir=/mnt/ssd/datadir --exec admin.nodeInfo |grep -Ev 'enode:|enr:|{|}'`
fi
if [ "$GETH_SYNCING" = "" ]; then
  GETH_SYNCING="NO DATA"
fi
if [ "$GETH_NODEINFO" = "" ]; then
  GETH_NODEINFO="NO DATA"
fi

echo '<!DOCTYPE html><head><title>Ethbian status</title><link rel="stylesheet" type="text/css" href="main.css" />' > $TARGET
echo '<meta charset="utf-8"></head><body><table>' >> $TARGET
echo "<tr><th>generated:</th><td>$NOW</td></tr>" >> $TARGET
echo "<tr><td colspan=\"2\"></td></tr>" >> $TARGET

echo "<tr><th>server uptime:</th><td>$UPTIME</td></tr>" >> $TARGET
echo "<tr><th>system load:</th><td>$LOAD</td></tr>" >> $TARGET
echo "<tr><th>temperature:</th><td>$TEMP</td></tr>" >> $TARGET
echo "<tr><th>root FS:</th><td><pre>$DF_ROOT</pre></td></tr>" >> $TARGET
echo "<tr><th>eth data FS:</th><td><pre>$DF_SSD</pre></td></tr>" >> $TARGET
echo "<tr><th>RAM (in MiB):</th><td><pre>$MEMORY</pre></td></tr>" >> $TARGET

echo "<tr><td colspan=\"2\"></td></tr>" >> $TARGET
echo "<tr><th>geth<br/>status</th><td><pre>$GETH_STATUS</pre></td></tr>" >> $TARGET

echo "<tr><td colspan=\"2\"></td></tr>" >> $TARGET
echo "<tr><th>geth<br/>syncing</th><td><pre>$GETH_SYNCING</pre></td></tr>" >> $TARGET

echo "<tr><td colspan=\"2\"></td></tr>" >> $TARGET
echo "<tr><th>geth.log<br/>(last 10 lines)</th><td><pre>$TAIL_GETH</pre></td></tr>" >> $TARGET

echo "<tr><td colspan=\"2\"></td></tr>" >> $TARGET
echo "<tr><th>syslog<br/>(last 10 lines)</th><td><pre>$TAIL_SYSLOG</pre></td></tr>" >> $TARGET

echo "<tr><td colspan=\"2\"></td></tr>" >> $TARGET
echo "<tr><th>geth<br/>nodeInfo</th><td><pre>$GETH_NODEINFO</pre></td></tr>" >> $TARGET

echo "</table></body></html>" >> $TARGET
