#!/bin/bash

echo ""
echo "*****************************************"
echo "*      ETHBIAN NETWORK CONFIG v0.1      *"
echo "*****************************************"
echo ""

IS_STATIC=`cat /etc/dhcpcd.conf |grep -c ^static`
if [ $IS_STATIC -eq 0 ]; then
  # DHCP
  whiptail --title ' network configuration ' \
  --backtitle 'Ethbian network configuration' \
  --yesno "\n             Looks like you're using DHCP.\n\n\
            Would you like to switch to static IP?" 10 60
  RESPONSE=$?
  if [ $RESPONSE -ne 0 ]; then
    echo "OK then..."
    exit 0
  fi
else

# -------------------------------------------- static to dhcp
  # STATIC
  whiptail --title ' network configuration ' \
  --backtitle 'Ethbian network configuration' \
  --yesno "\n       Looks like you're using static IP address.\n\n\
           Would you like to switch to DHCP?" 10 60
  RESPONSE=$?
  if [ $RESPONSE -eq 255 ]; then
    echo "OK then..."
    exit 0
  elif [ $RESPONSE -eq 0 ]; then
    echo -n "switching to DHCP... "
    sudo sed -i 's/^interface/#interface/' /eth/dhcpcd.conf
    sudo sed -i 's/^static/#static/' /eth/dhcpcd.conf
    echo "done"
    echo "Please restart your Pi for the applied changes to take effect"
    echo ""
    exit 0
  else
    whiptail --title ' network configuration ' \
    --backtitle 'Ethbian network configuration' \
    --yesno "\n\n          Would you like to change IP address?" 10 60
    RESPONSE=$?
    if [ $RESPONSE -ne 0 ]; then
      echo "OK then..."
      exit 0
    fi
  fi
fi

# -------------------------------------------- dhcp to static

# -------------- getting current dhcp config
CFG_IP=""
CFG_ROUTER=""
CFG_DNS=""
CFG_DNS1=""
CFG_DNS2=""

if [ $IS_STATIC -eq 0 ]; then
  CFG_IP=`hostname -I|cut -f 1 -d " "`
  if [ ${#CFG_IP} -ne 0 ]; then
    IP_ERR=`ipcalc $CFG_IP|grep -c INVALID`
    if [ $IP_ERR -ne 0 ]; then
      CFG_IP=""
    fi
  fi

  CFG_ROUTER=`ip route | grep default| cut -f 3 -d " "`
  if [ ${#CFG_ROUTER} -ne 0 ]; then
    ROUTER_ERR=`ipcalc $CFG_ROUTER|grep -c INVALID`
    if [ $ROUTER_ERR -ne 0 ]; then
      CFG_ROUTER=""
    fi
  fi

  for _DNS in `cat /etc/resolv.conf |grep ^nameserver |cut -f 2 -d " "`; do
    CFG_DNS="$CFG_DNS $_DNS"
  done
  CFG_DNS1=`echo $CFG_DNS|cut -f 1 -d " "`
  CFG_DNS2=`echo $CFG_DNS|cut -f 2 -d " "`
  if [ ${#CFG_DNS1} -ne 0 ]; then
    DNS1_ERR=`ipcalc $CFG_DNS1|grep -c INVALID`
    if [ $DNS1_ERR -ne 0 ]; then
      CFG_DNS1=""
    fi
  fi
  if [ ${#CFG_DNS2} -ne 0 ]; then
    DNS2_ERR=`ipcalc $CFG_DNS2|grep -c INVALID`
    if [ $DNS2_ERR -ne 0 ]; then
      CFG_DNS2=""
    fi
  fi
  if [ "$CFG_DNS1" == "$CFG_DNS2" ]; then
    CFG_DNS2=""
  fi

# -------------- getting current static config
else
  CFG_IP=`cat /etc/dhcpcd.conf |grep ^static|grep ip_address|cut -f 2 -d '='`
  CFG_ROUTER=`cat /etc/dhcpcd.conf |grep ^static|grep routers|cut -f 2 -d '='`
  CFG_DNS=`cat /etc/dhcpcd.conf |grep ^static|grep domain_name_servers|cut -f 2 -d '='`
  CFG_DNS1=`echo $CFG_DNS|cut -f 1 -d " "`
  CFG_DNS2=`echo $CFG_DNS|cut -f 2 -d " "`
  if [ "$CFG_DNS1" == "$CFG_DNS2" ]; then
    CFG_DNS2=""
  fi
fi

# -------------- getting new static config
exec 3>&1
VALUES=$(dialog --ok-label 'Save' \
	  --backtitle 'Ethbian network configuration' \
	  --title ' ip config ' \
	  --form 'static network configuration' \
11 60 0 \
	'IP (e.g. 192.168.1.10/24):'   1 1 "$CFG_IP"     1 28 19 0 \
	'gateway (your router IP):'       2 1 "$CFG_ROUTER" 2 28 19 0 \
	'DNS1:'   3 1 "$CFG_DNS1"    3 28 19 0 \
	'DNS2:'   4 1 "$CFG_DNS2"    4 28 19 0 \
2>&1 1>&3)
_CANCELLED=$?
exec 3>&-

if [ $_CANCELLED -ne 0 ]; then
  echo ""
  echo "OK then..."
  exit 0
fi

VALUES_LEN=`echo $VALUES|wc -w`
if [ $VALUES_LEN -lt 3 ]; then
  echo "--> all fields are required"
  exit 1
fi

CFG_IP=`echo $VALUES | cut -f 1 -d " "`
CFG_ROUTER=`echo $VALUES | cut -f 2 -d " "`
CFG_DNS1=`echo $VALUES | cut -f 3 -d " "`
CFG_DNS2=`echo $VALUES | cut -f 4 -d " "`

IP_ERR=`ipcalc $CFG_IP|grep -c INVALID`
ROUTER_ERR=`ipcalc $CFG_ROUTER|grep -c INVALID`
DNS1_ERR=`ipcalc $CFG_DNS1|grep -c INVALID`
DNS2_ERR=`ipcalc $CFG_DNS2|grep -c INVALID`

echo ""
if [ $IP_ERR -ne 0 ]; then echo "--> wrong IP address"; fi
if [ $ROUTER_ERR -ne 0 ]; then echo "--> wrong router address"; fi
if [ $DNS1_ERR -ne 0 ]; then echo "--> wrong first DNS address"; fi
if [ $DNS2_ERR -ne 0 ]; then echo "--> wrong second DNS address"; fi

if [ $IP_ERR -ne 0 ] || [ $ROUTER_ERR -ne 0 ] || [ $DNS1_ERR -ne 0 ] \
  || [ $DNS2_ERR -ne 0 ]; then
  echo "...but you can always try again"
  exit 1
fi

if [ $IS_STATIC -ne 0 ]; then
  sudo sed -i 's/^interface/#interface/' /etc/dhcpcd.conf
  sudo sed -i 's/^static/#static/' /etc/dhcpcd.conf
fi

sudo /bin/bash -c "cat << EOF >> /etc/dhcpcd.conf

interface eth0
static ip_address=$CFG_IP
static routers=$CFG_ROUTER
static domain_name_servers=$CFG_DNS1 $CFG_DNS2
EOF"
RESPONSE=$?
if [ $RESPONSE -eq 0 ]; then
    echo "Looks like we're good"
    echo "Please restart your Pi for the applied changes to take effect"
    exit 0
fi
