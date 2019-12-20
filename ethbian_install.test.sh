#!/bin/bash

echo ""
echo "*****************************************"
echo "*       ETHBIAN INSTALL TEST v0.4       *"
echo "*****************************************"
echo ""
echo "*RR - requires reboot"
echo ""

# ------------------- functions ------------------
function file_exists () {
    echo "Checking if $2 exists"
    if [ $1 $3 ]; then
        echo '          [OK]'
    else
        echo '          [ERROR]'
    fi
}

function exec_code_check () {
    echo $2
    eval "$1"
    if [ $? -ne 0 ]; then
        echo '          [ERROR]'
    else
        echo '          [OK]'
    fi
}

function exec_output_check () {
    echo $3
    OUTPUT=$(eval "$2")
    if [ $OUTPUT -ne $1 ]; then
        echo '          [ERROR]'
    else
        echo '          [OK]'
    fi
}

# --------------------- basic ethbian checks ----------------
exec_code_check 'id eth > /dev/null 2>&1' 'Checking if user eth exists: '
file_exists '-x' 'temp script' '/usr/local/bin/temp'
file_exists '-x' 'gsync script' '/usr/local/bin/gsync'
file_exists '-x' 'gat script' '/usr/local/bin/gat'
exec_output_check 0 'dpkg -l| grep dphys-swapfile| wc -l' 'Checking if dphys-swapfile package was removed: '
exec_output_check 0 'swapon -s |wc -w' 'Checking if swap is disabled (*RR): '
file_exists '! -L' 'wpa_supplicant does not' '/etc/systemd/system/multi-user.target.wants/wpa_supplicant.service'
exec_output_check 1 "ulimit -a |grep 'open files' |grep -c 32000" 'Checking if open files limit is increased (*RR): '
exec_output_check 0 'ifconfig |grep -c inet6' 'Checking if IPv6 is disabled (*RR): '
exec_output_check 16 '/usr/bin/vcgencmd get_mem gpu |cut -f 2 -d "=" |sed "s/.$//"' 'Checking GPUs memory (*RR): '
echo ''

# --------------------- hardware ----------------
exec_output_check 0 'iw dev |grep -c Interface' 'Checking if wifi is disabled: '
exec_output_check 0 'hciconfig |wc -l' 'Checking if bluetooth is disabled: '
exec_output_check 0 'aplay -l 2>/dev/null|wc -l' 'Checking if sound card is disabled: '
exec_output_check 0 'lsmod |grep -c bcm2835' 'Checking if camera modules are disabled: '
echo ''

# --------------------- geth ----------------
file_exists '-x' 'geth binary' '/usr/local/bin/geth/geth'
file_exists '-f' 'geth.service file' '/lib/systemd/system/geth.service'
exec_output_check 2 'grep -c geth /etc/rsyslog.conf' 'Checking syslog for geth: '
exec_code_check 'grep geth /etc/logrotate.d/geth 1> /dev/null' 'Checking logrotate for geth: '
echo ''

# --------------------- sudo ---------------
exec_output_check 1 "sudo grep -c 'eth ALL=(ALL) NOPASSWD:/opt/vc/bin/vcgencmd measure_temp' /etc/sudoers" \
    'Checking sudo configuration: '
exec_output_check 1 "sudo grep -c 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/syslog' /etc/sudoers" ''
exec_output_check 1 "sudo grep -c 'eth ALL=(ALL) NOPASSWD:/usr/bin/tail /var/log/geth.log' /etc/sudoers" ''

# --------------------- admin scripts ---------------
file_exists '-x' 'ethbian-net.sh script' '/usr/local/sbin/ethbian-net.sh'
file_exists '-x' 'ethbian-ssd-init.sh script' '/usr/local/sbin/ethbian-ssd-init.sh'
file_exists '-x' 'ethbian-geth-admin.sh script' '/usr/local/sbin/ethbian-geth-admin.sh'
file_exists '-x' 'ethbian-monitoring.sh script' '/usr/local/sbin/ethbian-monitoring.sh'
echo ''

# --------------------- influx -----------------
file_exists '-f' 'influxdb.conf file' '/etc/influxdb/influxdb.conf'
file_exists '-f' 'influxdb.conf.org file' '/etc/influxdb/influxdb.conf.org'
exec_code_check 'grep GOMAXPROCS /etc/default/influxdb 1> /dev/null' 'Checking GOMAXPROCS for influxdb: '
exec_code_check 'systemctl is-enabled --quiet influxdb' 'Checking if influxdb service is enabled: '
exec_code_check 'systemctl is-active --quiet influxdb' 'Checking if influxdb service is running: '
exec_output_check 2 'grep -c influxd /etc/rsyslog.conf' 'Checking syslog for influx: '
exec_code_check 'grep influx /etc/logrotate.d/influx 1> /dev/null' 'Checking logrotate for influx: '
echo ''

# --------------------- collectd ----------------
file_exists '-f' 'collectd.conf file' '/etc/collectd/collectd.conf'
file_exists '-f' 'collectd.conf.org file' '/etc/collectd/collectd.conf.org'
file_exists '-d' 'collectd directory' '/usr/local/lib/collectd'
file_exists '-f' 'rpi_temperature.py file' '/usr/local/lib/collectd/rpi_temperature.py'
file_exists '-f' 'geth_status.py file' '/usr/local/lib/collectd/geth_status.py'
exec_code_check 'systemctl is-enabled --quiet collectd' 'Checking if collectd service is enabled: '
exec_code_check 'systemctl is-active --quiet collectd' 'Checking if collectd service is running: '
exec_code_check 'grep collectd /etc/logrotate.d/collectd 1> /dev/null' 'Checking logrotate for collectd: '
echo ''

# --------------------- geth_peers_geo2influx ----------------
file_exists '-f' 'geolite_city.mmdb file' '/usr/local/lib/collectd/geolite_city.mmdb'
file_exists '-f' 'geth_peers_geo2influx.py file' '/usr/local/bin/geth_peers_geo2influx.py'
file_exists '-f' '/var/log/geo2influx.log file' '/var/log/geo2influx.log'
exec_output_check 1 'sudo grep -c geth_peers_geo2influx.py /var/spool/cron/crontabs/eth' 'Checking crontab for the eth user: '
exec_code_check 'grep geo2influx /etc/logrotate.d/geo2influx 1> /dev/null' 'Checking logrotate for geo2influx: '

# --------------------- eth_price2influx ----------------
file_exists '-f' 'eth_price2influx.py file' '/usr/local/bin/eth_price2influx.py'
file_exists '-f' '/var/log/price2influx.log file' '/var/log/price2influx.log'
exec_output_check 1 'sudo grep -c eth_price2influx.py /var/spool/cron/crontabs/eth' 'Checking crontab for the eth user: '
exec_code_check 'grep eth_price2influx /etc/logrotate.d/price2influx 1> /dev/null' 'Checking logrotate for eth_price2influx: '

# --------------------- grafana ----------------
file_exists '-f' 'grafana.ini file' '/etc/grafana/grafana.ini'
file_exists '-f' 'grafana.ini.org file' '/etc/grafana/grafana.ini.org'
exec_output_check 1 'sudo grafana-cli plugins ls |grep -c "grafana-worldmap-panel"' 'Checking grafana worldmap plugin: '
exec_output_check 1 'sudo grafana-cli plugins ls |grep -c "grafana-clock-panel"' 'Checking grafana clock plugin: '
exec_output_check 1 'curl -s -X GET -u admin:admin "http://127.0.0.1:3000/api/datasources" |grep -c InfluxDB' \
    'Checking if grafana imported datasource: '
exec_output_check 1 'curl -s -X GET -u admin:admin "http://127.0.0.1:3000/api/search/" |grep -c -E "eth_price.*geth_peers.*geth_status"' \
    'Checking if grafana imported dashboards: '
exec_output_check 1 'curl -s -X GET -u admin:admin "http://127.0.0.1:3000/api/search?starred=true" |grep -c -E "geth_peers.*geth_status"' \
    'Checking if grafana starred dashboards: '
exec_code_check 'systemctl is-enabled --quiet grafana-server' 'Checking if grafana service is enabled: '
exec_code_check 'systemctl is-active --quiet grafana-server' 'Checking if grafana service is running: '
