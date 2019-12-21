# ethbian

The easy way to run a full Ethereum node on Raspberry Pi 4  
**Ethbian = Raspbian + Geth + Grafana**  
Lastest version: **v0.4**  
Homepage: [https://ethbian.org](https://ethbian.org)  

## quick start

### installation

#### a) download ethbian image

Already prepared sd-card image can be found [here](https://ethbian.org/downloads/ethbian-v0.4-2019-12-21.img.gz)

| ethbian image file             | sha 256 checksum                                                 |
| ------------------------------ | ---------------------------------------------------------------- |
| ethbian-v0.4-2019-12-21.img.gz | 9a5957532a841b96f051dabb50845d51317c570d0f8053a5d169906630f61a36 |

To verify the checksum of a downloaded file:

| system | command                  |
| ------ | ------------------------ |
| Mac    | shasum -a 256 _filename_ |
| Linux  | sha256sum _filename_     |

#### b) or create your own image

- download & install Raspbian Buster Lite
- login (user: pi/pass: raspberry) and execute:

> wget https://raw.githubusercontent.com/ethbian/ethbian/master/ethbian_install.sh && bash ethbian_install.sh

- restart the box
- login again (user: pi/pass: ethbian)

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

You can use the **ethbian-ssd-init.sh** script to initialize a new disk drive.  
The script will wipe it out completely and create a maximum size single partition.  
SSD should be mounted to **/mnt/ssd** directory with **datadir** subdirectory created  
within (user **eth** should be the owner).

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

For more details visit [https://ethbian.org](https://ethbian.org)
