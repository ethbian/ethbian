# ethbian

The easy way to run a full Ethereum node on Raspberry Pi 4

## quick start

### installation

#### a) download ethbian image

Already prepared sd-card image can be found [here](https://ethbian.org/downloads/ethbian-v0.2-2019-12-05.img.gz)

| ethbian image file             | sha 256 checksum                                                 |
| ------------------------------ | ---------------------------------------------------------------- |
| ethbian-v0.2-2019-12-05.img.gz | e01465da0327cbf57e9ab2e9881d1c19c79c862b791c9d7d2bdb2bc85ff8b99c |

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

The **ethbian-geth-upgrade.sh** will upgrade your geth the the latest version.

#### start geth

With network configured and disk mounted you are ready to go.  
**sudo systemctl start geth** will start geth.  
**sudo systemctl enable geth** will make it start automatically on boot.

#### geth & RPi stats

By default Grafana is running on port 3000 with default user **admin** and password **admin**.  
You can monitor RPi temperature, system load and memory usage and some basic geth stats.

#### files

**/lib/systemd/system/geth.service** :geth settings  
**/usr/local/bin/geth/geth** :geth binary.  
**/usr/local/sbin** :admin scripts

**temp** :shows Pi's temperature  
**gat** :attach to geth console  
**/var/log/geth.log** :geth logs

For more details visit [https://ethbian.org](https://ethbian.org)
