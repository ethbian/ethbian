#!/bin/bash

echo ""
echo "*****************************************"
echo "*          ETHBIAN 64BIT v0.1           *"
echo "*****************************************"
echo ""

CURRENT=`uname -m`
if [ "$CURRENT" = "aarch64" ]; then
  echo ""
  echo "You're already running 64bit kernel."
  echo ""
  exit 1
fi

grep -q ^'arm_64bit=1' /boot/config.txt
if [ $? -eq 0 ]; then
  echo ""
  echo "Your system is ready."
  echo "Please restart the box."
  echo ""
  exit 1
fi

echo "### updating the package list..."
echo ""
sudo apt-get -y update
echo ""
echo "### full-upgrading the system..."
echo ""
sudo apt-get -y full-upgrade
echo ""
echo "### updating the bootloader EEPROM"
echo ""
sudo rpi-eeprom-update -a
echo ""
echo "### switching to 64bit kernel"
echo ""
sudo /bin/bash -c 'echo arm_64bit=1 >> /boot/config.txt'
echo ""
echo "Done. Please restart the box."
echo ""