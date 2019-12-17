#!/bin/bash

echo ""
echo "*****************************************"
echo "*    ETHBIAN SD CARD IMAGE SETUP v0.4   *"
echo "*****************************************"
echo ""

function create_logrotate_config () {
  sudo /bin/bash -c "cat << EOF > /etc/logrotate.d/$1
/var/log/$2
{
  rotate 7
  daily
  missingok
  notifempty
  delaycompress
  compress
  postrotate
    /usr/lib/rsyslog/rsyslog-rotate
  endscript
}
EOF"
}

echo -n "### Detecting CPU architecture... "
isARM=$(uname -m | grep -c 'arm')
if [ ${isARM} -eq 0 ]; then
  echo "!!! FAIL !!!"
  echo "   This version can only run on ARM architecture"
  exit 1
else
  echo "OK"
fi

echo -n "### Detecting base image... "
isRaspbian=$(cat /etc/os-release 2>/dev/null | grep -c 'Raspbian')
if [ ${isRaspbian} -eq 0 ]; then
  echo "!!! FAIL !!!"
  echo "   This version can only run on Raspbian"
  exit 1
else
  echo "OK"
fi

echo ""
echo "### Updating system..."
echo ""
sudo apt-get -y update
echo ""
echo "### Upgrading system..."
echo "   this may take a while"
echo ""
sudo apt-get -y upgrade
echo ""
echo "### Update & upgrade finished"
echo ""
echo ""


echo "### Config"

echo "  # adding eth user..."
sudo adduser --shell /bin/bash --gecos "" --disabled-login eth
echo ""

echo "  # changing hostname..."
sudo /bin/bash -c 'echo "ethbian" > /etc/hostname'
sudo sed -i "s/^127.0.1.1.*/127.0.1.1\tethbian/" /etc/hosts
echo ""

echo "  # changing passwords..."
echo "pi:ethbian" | sudo chpasswd
sudo passwd -e pi
echo ""

echo "  # installing tools..."
echo ""
sudo apt-get install -y git jq dstat lsof nmap screen tmux fail2ban dialog sysstat ipcalc sqlite3 software-properties-common
if [ ! -d /mnt/ssd ]; then
  sudo mkdir /mnt/ssd
fi

sudo /bin/bash -c 'cat << EOF > /usr/local/bin/temp
#!/bin/sh
/opt/vc/bin/vcgencmd measure_temp
EOF'
sudo chmod +x /usr/local/bin/temp

/bin/bash -c 'cat << EOF >> /home/pi/.bashrc

# show pi temperature
echo 
echo ------------------
echo -n "  Pi "
/opt/vc/bin/vcgencmd measure_temp
echo ------------------
EOF'

sudo /bin/bash -c 'cat << EOF > /usr/local/bin/gat
#!/bin/sh
/usr/local/bin/geth/geth attach --datadir=/mnt/ssd/datadir
EOF'
sudo chmod +x /usr/local/bin/gat

sudo /bin/bash -c 'cat << EOF > /etc/motd

    --- Welcome to Ethbian! ---
               v0.4

admin commands (for the 'pi' user):
  ethbian-net.sh - simple network configuration
  ethbian-geth-admin.sh - upgrade geth binary
  ethbian-ssd-init.sh - ssd drive init
  ethbian-monitoring.sh - system/geth monitoring on/off

after configuring network and ssd drive:
- to start geth: sudo systemctl start geth
- to run geth on startup: sudo systemctl enable geth

grafana is running on port 3000
(user: admin, password: admin)

SSD drive is a must.
Active cooling is highly recommended.

For more details visit https://ethbian.org

EOF'

echo ""
echo -e "\nalias gat='sudo /usr/local/bin/gat'" >> /home/pi/.bashrc

cd /tmp
git clone https://github.com/ethbian/ethbian.git
cd ethbian

chmod +x admin/scripts/*
sudo mv admin/scripts/* /usr/local/sbin
sudo chown root:root /usr/local/sbin/ethbian*

echo "  # disabling swap..."
echo ""
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo apt-get purge -y dphys-swapfile
echo ""

echo "  # removing wpa_supplicant..."
echo ""
sudo systemctl disable wpa_supplicant
echo ""

echo "   # increasing open files limits..."
sudo /bin/bash -c 'cat << EOF > /etc/security/limits.d/90-geth.conf
*    soft nofile 32000
*    hard nofile 32000
root soft nofile 32000
root hard nofile 32000
EOF'
echo ""

echo "  # disabling IPv6..."
sudo /bin/bash -c 'cat << EOF >> /etc/sysctl.d/99-sysctl.conf
# disable ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF'
echo ""

echo "### Hardware"

echo "  # disabling wifi..."
sudo /bin/bash -c 'echo "dtoverlay=disable-wifi" >> /boot/config.txt'
echo ""

echo "  # disabling bluetooth..."
sudo /bin/bash -c 'echo "dtoverlay=disable-bt" >> /boot/config.txt'
echo ""

echo "  # disabling sound card..."
sudo sed -i 's/dtparam=audio=on/dtparam=audio=off/' /boot/config.txt
echo ""

echo "  # reassigning memory from GPU to CPU..."
sudo /bin/bash -c 'echo "gpu_mem=16" >> /boot/config.txt'
echo ""

echo "  # disabling camera modules..."
sudo /bin/bash -c 'echo -e "blacklist bcm2835_codec\nblacklist bcm2835_v4l2" > /etc/modprobe.d/disable_rpi4_camera.conf'
echo ""

sudo /bin/bash -c "echo 'eth ALL=(ALL) NOPASSWD:/opt/vc/bin/vcgencmd measure_temp' >> /etc/sudoers"
sudo /bin/bash -c "echo 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/syslog' >> /etc/sudoers"
sudo /bin/bash -c "echo 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/geth.log' >> /etc/sudoers"

sudo sed -i '/^exit/itest -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server' /etc/rc.local

echo "### GETH"
/usr/local/sbin/ethbian-geth-admin.sh -i

echo "  # syslog..."
sudo sed -i "/^auth/i :programname, isequal, \"geth\" \/var\/log\/geth.log" /etc/rsyslog.conf
sudo sed -i "/^auth/i :programname, isequal, \"geth\" stop" /etc/rsyslog.conf

create_logrotate_config 'geth' 'geth.log'

echo "### Monitoring"
GITHUB_RPI_TEMP='https://raw.githubusercontent.com/ethbian/rpi_temperature_plugin4collectd/master/rpi_temperature.py'
GITHUB_GETH_STATUS='https://raw.githubusercontent.com/ethbian/geth_status_plugin4collectd/master/geth_status.py'

echo ""
echo "  # installing monitoring tools..."
sudo apt-get install -y collectd collectd-utils influxdb influxdb-client python-influxdb python-geoip2
cd /tmp/ethbian
echo ""

echo "  # influx..."
sudo systemctl stop influxdb
sudo mv /etc/influxdb/influxdb.conf /etc/influxdb/influxdb.conf.org
sudo mv admin/conf/influxdb.conf /etc/influxdb/
sudo /bin/bash -c 'echo "GOMAXPROCS=1" >> /etc/default/influxdb'
sudo systemctl enable influxdb
sudo sed -i "/^auth/i :programname, isequal, \"influxd\" \/var\/log\/influx.log" /etc/rsyslog.conf
sudo sed -i "/^auth/i :programname, isequal, \"influxd\" stop" /etc/rsyslog.conf
create_logrotate_config 'influx' 'influx.log'
echo ""

echo "  # collectd..."
sudo systemctl stop collectd
sudo mv /etc/collectd/collectd.conf /etc/collectd/collectd.conf.org
sudo mv admin/conf/collectd.conf /etc/collectd/
sudo mkdir /usr/local/lib/collectd
cd /usr/local/lib/collectd
sudo wget $GITHUB_RPI_TEMP
sudo wget $GITHUB_GETH_STATUS
sudo systemctl enable collectd
create_logrotate_config 'collectd' 'collectd.log'
echo ""

echo "  # geth_peers_geo2influx..."
GEODB_FILE='GeoLite2-City.tar.gz'
GEO_SCRIPT='geth_peers_geo2influx.py'
GEO_LOG='/var/log/geo2influx.log'
GITHUB_GEO2INFLUX='https://raw.githubusercontent.com/ethbian/geth_peers_geo2influx/master/'

cd /tmp
wget https://geolite.maxmind.com/download/geoip/database/$GEODB_FILE
if [ -f $GEODB_FILE ]; then
  sudo tar -zxf $GEODB_FILE --directory /usr/local/lib/collectd --strip-components 1 --wildcards GeoLite2-City_*/GeoLite2-City.mmdb
  if [ $? -eq 0 ]; then
    sudo mv /usr/local/lib/collectd/GeoLite2-City.mmdb /usr/local/lib/collectd/geolite_city.mmdb
  fi
fi
sudo touch $GEO_LOG
sudo chown eth $GEO_LOG
create_logrotate_config 'geo2influx' 'geo2influx.log'
cd /usr/local/bin
sudo wget ${GITHUB_GEO2INFLUX}${GEO_SCRIPT}
sudo chmod +x $GEO_SCRIPT

sudo touch /var/spool/cron/crontabs/eth
sudo chown eth:crontab /var/spool/cron/crontabs/eth
sudo chmod 0600 /var/spool/cron/crontabs/eth
sudo /bin/bash -c "echo 'SHELL=/bin/bash' > /var/spool/cron/crontabs/eth"
sudo /bin/bash -c "echo '*/30 * * * * /usr/local/bin/$GEO_SCRIPT >> $GEO_LOG 2>&1' >> /var/spool/cron/crontabs/eth"

echo "  # grafana..."
cd /tmp/ethbian
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo /bin/bash -c 'echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list'
sudo apt-get update
sudo apt-get install -y grafana

sudo systemctl stop grafana-server
sudo cp /etc/grafana/grafana.ini /etc/grafana/grafana.ini.org
sudo sed -i 's/^;reporting_enabled = true/reporting_enabled = false/' /etc/grafana/grafana.ini
sudo sed -i 's/^;check_for_updates = true/check_for_updates = false/' /etc/grafana/grafana.ini
sudo sed -i 's/^;level = info/level = warn/' /etc/grafana/grafana.ini
sudo sed -i '/Enable internal metrics/!b;n;cenabled = false' /etc/grafana/grafana.ini
sudo sed -i 's/^;disable_total_stats = false/disable_total_stats = true/' /etc/grafana/grafana.ini
sudo sed -i 's/^;allow_sign_up = true/allow_sign_up = false/' /etc/grafana/grafana.ini
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sleep 3
sudo systemctl stop grafana-server
sudo grafana-cli plugins install grafana-worldmap-panel
cat admin/conf/grafana_ds_influx.sql | sudo sqlite3 /var/lib/grafana/grafana.db
cat admin/conf/grafana_dash_geth_status.sql | sudo sqlite3 /var/lib/grafana/grafana.db
cat admin/conf/grafana_dash_geth_peers.sql | sudo sqlite3 /var/lib/grafana/grafana.db
cat admin/conf/grafana_star.sql | sudo sqlite3 /var/lib/grafana/grafana.db

echo "### Cleaning up"
sudo apt-get purge -y avahi-daemon mariadb-common mysql-common libvirt0 openjdk-11-jre-headless adwaita-icon-theme
sudo apt -y autoremove

echo "### Done."
