# ethbian

The easy way to run a full Ethereum node on Raspberry Pi 4  
**Ethbian = Raspbian + Geth + Grafana**  
Lastest version: **v0.6**  

## quick start

### installation
#### create your own image

- download & install Raspbian Buster Lite
- login (user: pi/pass: raspberry) and execute:

> wget https://raw.githubusercontent.com/ethbian/ethbian/master/ethbian_install.sh && bash ethbian_install.sh

- restart the box
- login again (user: pi/pass: ethbian)
- register (free) for a MaxMind account and obtain a license key in order to download GeoLite2 database (free)  
  Visit [MaxMind page](https://www.maxmind.com/en/geolite2/signup) to register, [download](https://www.maxmind.com/en/accounts/214108/geoip/downloads) the GeoLite2City db and  
  save the file as /usr/local/lib/collectd/geolite_city.mmdb

## first steps

default user: **pi**  
defualt pass: **ethbian**

#### what you should know

- swap is disabled
- wifi is disabled
- IPv6 is disabled
- bluetooth is disabled
- sound card is disabled
- camera modules are disabled
- unnecessary services are disabled

#### network configuration

You can use a simple **ethbian-net.sh** script to configure network.  
You can also use standard **raspi-config** tool to do the same.  
Remember that wifi is disabled - use wired connection instead:  
lower latency, reliable connection, speed.

#### SSD disk configuration

You can use the **ethbian-ssd-init.sh** script to initialize a new disk drive  
or remount your partition after upgrading Ethbian.  
If you prefer to do this manually - SSD should be mounted to the **/mnt/ssd** directory  
with **datadir** subdirectory created within (user **eth** should be the owner).

#### switching to 64bit kernel

Because of memory allocation problem with the latest Raspbian and RPi4  
you should switch to 64bit kernel - by executing the **ethbian-64bit.sh** script.  
If you don't - when fully synced, geth will crash every couple of minutes/hours  
causing your Pi to hang eventually.

#### geth upgrade

The "**ethbian-geth-admin.sh -u**" will upgrade your geth to the latest version.

#### system/geth monitoring

Ethbian monitoring:

- collectd (collects system/geth data)
- geth_peers_geo2influx.py script (geolocation, eth's crontab)
- eth_price2influx.py script (eth price, eth's crontab)
- influx database (data storage)
- grafana (data visualization)

Use the **ethbian-monitoring.sh** command do disable/enable these services  
or check their status.

#### geth & RPi stats dashboard

When monitoring services are running you can monitor RPi temperature, system load  
and memory usage and some basic geth stats with a web browser:  
Grafana is running on port 3000 with default user **admin** and password **admin**.  
Just launch Firefox/Chrome/Safari and enter the following URL:  
**http<nolink>://pi's_IP_address:3000**, eg. http<nolink>://192.168.1.33:3000

#### start geth

With network configured and disk mounted you are ready to go.  
**sudo systemctl start geth** will start geth.  
**sudo systemctl enable geth** will make it start automatically on boot.

#### files

**/lib/systemd/system/geth.service** :geth settings  
**/usr/local/bin/geth/geth** :geth binary.  
**/usr/local/sbin** :admin scripts

**temp** :shows CPU temperature  
**gat** :attach to geth console  
**gsync** :shows geth synchronization progress  
**/var/log/geth.log** :geth logs
