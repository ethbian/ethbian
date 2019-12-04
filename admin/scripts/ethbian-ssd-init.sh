#!/bin/bash

echo ""
echo "*****************************************"
echo "*        ETHBIAN SSD CONFIG v0.1        *"
echo "*****************************************"
echo ""

ALREADY_MOUNTED=`grep -c '/mnt/ssd' /proc/mounts`
if [ $ALREADY_MOUNTED -ne 0 ]; then
  echo ""
  echo "There's already a file system mounted to the /mnt/ssd directory."
  echo "      You need to unmount it first and try again."
  echo ""
  exit 1
fi

DRIVES=`lsblk -S -n -o NAME`
NR=`echo $DRIVES |wc -w`
if [ $NR -eq 0 ]; then
  echo ""
  echo "             No disks detected."
  echo "Please make sure they're connected and try again."
  echo ""
elif [ $NR -ne 1 ]; then
  echo "             detected drives:"
  echo ""
  for DRIVE in $DRIVES; do
    DESC=`lsblk -S -n -o SIZE,VENDOR,MODEL /dev/$DRIVE`
    echo $DRIVE [$DESC]
  done
  echo ""
  echo "Which one would you like to use? (sda/sdb....)"
  read DRIVE
  if [ ! -b /dev/$DRIVE ]; then
    echo ""
    echo "The device does not exist"
    echo "    Please try again"
    echo ""
    exit 1
  fi
else
  DRIVE=$DRIVES
  DESC=`lsblk -S -n -o SIZE,VENDOR,MODEL /dev/$DRIVE`
fi

whiptail --title ' disk drive ' \
  --backtitle 'Ethbian storage device configuration' \
  --defaultno \
  --yesno "            selected drive for geth storage:\n\n $DRIVE [$DESC]\n\n\
                       Is it OK?" 11 60
  RESPONSE=$?
  if [ $RESPONSE -ne 0 ]; then
    echo "OK then..."
    exit 0
  fi

ALREADY_MOUNTED=`grep -c "/dev/$DRIVE" /proc/mounts`
if [ $ALREADY_MOUNTED -ne 0 ]; then
  echo ""
  echo "At least one partition of the drive has already been mounted."
  echo "      You need to unmount it first and try again:"
  echo ""
  grep /dev/$DRIVE /proc/mounts
  echo ""
  exit 1
fi

IS_HDD=`cat /sys/block/$DRIVE/queue/rotational`
if [ $IS_HDD -ne 0 ]; then
  whiptail --title ' disk drive ' \
    --backtitle 'Ethbian storage device configuration' \
    --defaultno \
    --yesno "\n   A solid state drive (SSD) is needed to sync a node.\n\
        $DRIVE looks like a traditonal drive (HDD).\n\n\
            Do you want to continue anyway?" 11 60
    RESPONSE=$?
    if [ $RESPONSE -ne 0 ]; then
      echo "OK then..."
      exit 0
    fi
fi

DISK_SIZE=`lsblk -o SIZE /dev/$DRIVE -b -n -S`
if [ $DISK_SIZE -lt 190000000000 ]; then
  whiptail --title ' disk drive ' \
    --backtitle 'Ethbian storage device configuration' \
    --defaultno \
    --yesno "\n         Recommended disk size is at least 200GB.\n\
            Do you want to continue anyway?" 9 60
    RESPONSE=$?
    if [ $RESPONSE -ne 0 ]; then
      echo "OK then..."
      exit 0
    fi
fi

whiptail --title ' disk drive ' \
  --backtitle 'Ethbian storage device configuration' \
  --defaultno \
  --yesno "   A single partition with all available disk size
        will be created and mounted in /mnt/ssd.\n
                       Are you sure?" 10 60
RESPONSE=$?
if [ $RESPONSE -ne 0 ]; then
  echo "OK then..."
  exit 0
fi

whiptail --title ' disk drive ' \
  --backtitle 'Ethbian storage device configuration' \
  --defaultno \
  --yesno "                   Say Yes again,
             I dare you, I double dare you...\n
        (all existing data on $DRIVE will be lost)  
                     Are you sure?" 11 60
RESPONSE=$?
if [ $RESPONSE -ne 0 ]; then
  echo "OK then..."
  exit 0
fi

sudo wipefs -a /dev/$DRIVE
if [ $? -ne 0 ]; then
  echo -e "\n   wipefs error\n"
  exit 1
fi
echo -e "\nwipefs: [OK]\n"

# y: just in case of signature confirmation
sudo fdisk /dev/$DRIVE <<EOF
n
p
1


y
w
EOF
if [ $? -ne 0 ] && [ -b /dev/${DRIVE}1 ]; then
  echo -e "\n   fdisk error\n"
  exit 1
fi
echo -e "\nfdisk:  [OK]\n"

sudo mkfs.ext4 -F /dev/${DRIVE}1
if [ $? -ne 0 ]; then
  echo -e "\n   mkfs.ext4 error\n"
  exit 1
fi
echo -e "\nmkfs:   [OK]\n"

sudo e2label /dev/${DRIVE}1 GETH_DATADIR
sudo blkid /dev/${DRIVE}1
blkid /dev/${DRIVE}1 |grep GETH_DATADIR
if [ $? -ne 0 ]; then
  echo -e "\ne2label:   [WARNING]\n"
else
  echo -e "\ne2label:   [OK]\n"
fi

SSD_PARTUUID=`lsblk -no PARTUUID /dev/${DRIVE}1`
if [ ${#SSD_PARTUUID} -eq 0 ]; then
  echo -e "\n   error getting PARTUUID\n"
  exit 1
fi
SSD_FSTAB="PARTUUID=$SSD_PARTUUID /mnt/ssd  ext4  defaults,noatime  0 2"

sudo /bin/bash -c "echo '${SSD_FSTAB}' >> /etc/fstab"
if [ $? -ne 0 ]; then
  echo -e "\n   /etc/fstab update error\n"
  exit 1
fi
echo -e "\n/etc/fstab update:   [OK]\n"

sudo mount /mnt/ssd
if [ $? -ne 0 ]; then
  echo -e "\n   mounting /mnt/ssd error\n"
  exit 1
fi

CMD=`mountpoint -q /mnt/ssd`
if [ $? -ne 0 ]; then
  echo -e "\n   mounting /mnt/ssd error\n"
  exit 1
fi
echo -e "\nmounting /mnt/ssd:   [OK]\n"

if [ ! -d /mnt/ssd/datadir ]; then
  sudo mkdir /mnt/ssd/datadir
fi

sudo chown eth:eth /mnt/ssd/datadir
if [ $? -ne 0 ]; then
  echo -e "\n   changing ownership of /mnt/ssd/datadir error\n"
  exit 1
fi

echo ""
echo "Your disk is ready."
echo ""
echo "Configuring geth to start automatically on boot"
echo ""
if [ ! -L /etc/systemd/system/multi-user.target.wants/geth.service ]; then
  sudo systemctl enable geth.service
fi

echo ""
echo "You're ready to go."
echo ""
