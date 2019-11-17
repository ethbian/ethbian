#!/bin/bash

echo ""
echo "*****************************************"
echo "*    ETHBIAN SD CARD IMAGE SETUP v0.1   *"
echo "*****************************************"
echo ""

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
sudo apt-get install -y jq dstat lsof nmap screen tmux fail2ban dialog sysstat ipcalc webfs
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

admin commands (for the 'pi' user):
  ethbian-net.sh - simple network configuration
  ethbian-ssd-init.sh - ssd drive init

after configuring network and ssd drive:
- to start geth: sudo systemctl start geth
- to run geth on startup: sudo systemctl enable geth

web server (with system stats) is running on port 8000
(user: eth, password: eth)

SSD drive is a must.
Active cooling is highly recommended.

For more details visit http://ethbian.org

EOF'

echo ""
echo -e "\nalias gat='sudo /usr/local/bin/gat'" >> /home/pi/.bashrc

GITHUB_FROM='https://raw.githubusercontent.com/ethbian/ethbian/master'
ADMIN_FILES='ethbian-net.sh ethbian-ssd-init.sh'
cd /usr/local/sbin
for FILE in $ADMIN_FILES; do
  sudo wget $GITHUB_FROM/$FILE && sudo chmod +x $FILE
done

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

echo "  # disabling camera modules..."
sudo /bin/bash -c 'echo -e "blacklist bcm2835_codec\nblacklist bcm2835_v4l2" > /etc/modprobe.d/disable_rpi4_camera.conf'
echo ""

echo ""

echo "### webfs & status"

echo "  # files and directories..."
sudo mkdir -p /var/www/html
sudo touch /var/www/html/index.html
sudo chown eth:eth /var/www/html/index.html
echo ""

echo "  # config file..."
sudo sed -i 's/^web_extras=""/web_extras="-b eth:eth"/' /etc/webfsd.conf
sudo sed -i 's/^web_index=""/web_index="index.html"/' /etc/webfsd.conf
echo ""

echo "  # crontab and status..."
FILE='status2html-cron.sh'
cd /home/eth
sudo wget $GITHUB_FROM/$FILE && sudo chmod +x $FILE && sudo chown eth:eth $FILE
if [ -x $FILE ]; then
  sudo /bin/bash -c "echo '*/5 * * * * /home/eth/'$FILE > /var/spool/cron/crontabs/eth"
  sudo chown eth:crontab /var/spool/cron/crontabs/eth
  sudo chmod 0600 /var/spool/cron/crontabs/eth
fi

sudo /bin/bash -c "echo 'eth ALL=(ALL) NOPASSWD:/opt/vc/bin/vcgencmd measure_temp' >> /etc/sudoers"
sudo /bin/bash -c "echo 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/syslog' >> /etc/sudoers"
sudo /bin/bash -c "echo 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/geth.log' >> /etc/sudoers"

sudo /bin/bash -c 'cat << EOF > /var/www/html/main.css
body {
  font-family: Arial, Helvetica, sans-serif;
}

table {
  border: solid 1px #ddeeee;
  border-collapse: collapse;
  border-spacing: 0;
  margin-left: auto;
  margin-right: auto;
}

th {
  background-color: #ddefef;
  border: solid 1px #ddeeee;
  color: #336b6b;
  padding: 10px;
  text-align: left;
  text-shadow: 1px 1px 1px #fff;
}

td {
  border: solid 1px #ddeeee;
  color: #333;
  padding: 10px;
  text-shadow: 1px 1px 1px #fff;
}

pre {
    white-space: pre-wrap;
    white-space: -moz-pre-wrap;
    white-space: -pre-wrap;
    white-space: -o-pre-wrap;
    word-wrap: break-word;
}
EOF'

echo ""

echo "### GETH"
GETH_BINARY='geth-linux-arm7-1.9.7-a718daa6.tar.gz'
GETH_ASC='geth-linux-arm7-1.9.7-a718daa6.tar.gz.asc'

echo "  # downloading the package..."
echo ""
cd /tmp
wget https://gethstore.blob.core.windows.net/builds/$GETH_BINARY
wget https://gethstore.blob.core.windows.net/builds/$GETH_ASC
echo ""

echo "  # verifying..."
gpg --keyserver keyserver.ubuntu.com --recv-keys 9BA28146
gpg --verify $GETH_ASC $GETH_BINARY
if [ $? -ne 0 ] ; then 
  echo " geth gpg verification error! "
  exit 1
fi
echo ""

echo "  # installing..."
GETH_DIR=`echo $GETH_BINARY | sed 's/.tar.gz//'`
cd /usr/local/bin
sudo tar zxf /tmp/$GETH_BINARY
if [ ! -d $GETH_DIR ]; then
  echo " error unpacking geth binary "
  exit 1
fi
sudo chown -R root:root $GETH_DIR
if [ -L 'geth' ]; then
  sudo rm geth
fi
sudo ln -s $GETH_DIR geth
sudo /bin/bash -c 'echo "export PATH=\$PATH:/usr/local/bin/geth" >> /etc/profile'

if [ ! -f /lib/systemd/system/geth.service ]; then
  sudo /bin/bash -c 'cat << EOF > /lib/systemd/system/geth.service
[Unit]
Description=geth
After=network.target

[Service]
User=eth
Group=eth
ExecStart=/usr/local/bin/geth/geth --datadir=/mnt/ssd/datadir --cache 256 --syncmode fast --maxpeers 50 --light.maxpeers 10
KillMode=process
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF'
fi

if [ ! -L /etc/systemd/system/geth.service ]; then
  sudo ln -s /lib/systemd/system/geth.service /etc/systemd/system/
fi

echo "  # syslog..."
sudo sed -i "/^auth/i :programname, isequal, \"geth\" \/var\/log\/geth.log" /etc/rsyslog.conf
sudo sed -i "/^auth/i :programname, isequal, \"geth\" stop" /etc/rsyslog.conf

sudo /bin/bash -c 'cat << EOF > /etc/logrotate.d/geth
/var/log/geth.log
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
EOF'

echo "### Done."