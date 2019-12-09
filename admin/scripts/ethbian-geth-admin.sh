#!/bin/bash

echo ''
echo '*****************************************'
echo '*        ETHBIAN GETH ADMIN  v0.2       *'
echo '*****************************************'
echo ''

INSTALLDIR='/usr/local/bin'
DOWNDIR='/tmp'
REPO='https://gethstore.blob.core.windows.net/builds/'
TARGET='geth-linux-arm7-VERSION-HASH'
GPGBUILDER='9BA28146'
GPGKEYSRV='keyserver.ubuntu.com'
TOOLS='readlink curl jq wget gpg tar'

function checks_common () {
   if [ ! -d $INSTALLDIR ]; then
      echo '   Installation directory does not exist.'
      exit 1
   fi

   for tool in $TOOLS
   do
      hash $tool 2>/dev/null
      if [ $? -ne 0 ]; then
         echo ''
         echo "       $tool command not found."
         echo 'Install the missing binary and try again.'
         echo ''
         exit 1
      fi
   done
}

function checks4upgrade () {
   cd $INSTALLDIR
   if [ ! -L geth ]; then
      echo 'symlink geth in the installation directory does not exist.'
      exit 1
   fi

   LINK=`readlink geth`
   OLDVER=v`echo $LINK| cut -f 4 -d "-"`
}

function check_new_version() {
   NEWVER=`curl --silent 'https://api.github.com/repos/ethereum/go-ethereum/releases/latest' | jq -r .tag_name`
   if [ $? -ne 0 ]; then
      echo 'something went wrong, try again later.'
      exit 1
   fi
}

function compare_versions() {
   if [ "$OLDVER" == "$NEWVER" ]; then
      echo ''
      echo 'The latest geth version is already installed.'
      exit 0
   fi
}

function install_new_version () {
   echo ''
   echo 'Trying to download the files...'
   cd $DOWNDIR
   echo -n '   - getting the SHA: '
   SHA=`curl --silent https://api.github.com/repos/ethereum/go-ethereum/commits/tags/$NEWVER | jq -r .sha`
   if [ $? -ne 0 ]; then
      echo 'something went wrong, try again later.'
      exit 1
   fi
   echo $SHA

   VERSION=`echo $NEWVER| cut -c 2-`
   HASH=`echo $SHA| cut -c 1-8`
   TARGET=`echo $TARGET| sed "s/HASH/$HASH/"`
   TARGET=`echo $TARGET| sed "s/VERSION/$VERSION/"`

   cd $DOWNDIR
   echo '   - getting the signature file: '
   wget -q --show-progress "${REPO}${TARGET}.tar.gz.asc"
   if [ $? -ne 0 ]; then
      echo 'something went wrong, try again later.'
      exit 1
   fi
   if [ ! -f ${TARGET}.tar.gz.asc ]; then
      echo 'something went wrong, try again later.'
      exit 1
   fi

   echo '   - getting the binary file: '
   wget -q --show-progress "${REPO}${TARGET}.tar.gz"
   if [ $? -ne 0 ]; then
      echo 'something went wrong, try again later.'
      exit 1
   fi
   if [ ! -f ${TARGET}.tar.gz ]; then
      echo 'something went wrong, try again later.'
      exit 1
   fi

   echo ''
   echo '   - checking the signature file:'
   gpg --keyserver $GPGKEYSRV --recv $GPGBUILDER
   gpg --verify ${TARGET}.tar.gz.asc
   if [ $? -ne 0 ]; then
      echo 'Signature verification failed.'
      exit 1
   fi

   echo ''
   echo -n '   - unpacking the file: '
      sudo tar -zxf ${TARGET}.tar.gz -C $INSTALLDIR
   if [ $? -ne 0 ]; then
      echo 'error unpacking the file.'
      exit 1
   fi
   echo 'OK'

   echo ''
   cd $INSTALLDIR
   if [ ! -d ${TARGET} ]; then
      echo 'Target installation directory does not exist.'
      exit 1
   fi
   sudo chown -R root:root ${TARGET}

   if [ "$1" = true ]; then
      systemctl is-active --quiet geth
      if [ $? -ne 0 ]; then
         GETH_RUNNING=false
         echo '          geth (service) is not running.'
         echo 'After upgrading it will not be started automatically.'
      else
         GETH_RUNNING=true
         echo '          geth (service) is running.'
         echo 'After upgrading it will be started automatically.'
      fi

      echo ''
      if [ "$GETH_RUNNING" = true ]; then
         echo -n '   - stopping geth service'
         sudo systemctl stop geth
      fi

      echo ''
      echo -n '   - removing existing symlink (to the current geth version): '
      sudo rm geth
      if [ $? -ne 0 ]; then
         echo 'error removing the file.'
         exit 1
      fi
      echo 'OK'
   else
      GETH_RUNNING=false
      sudo /bin/bash -c 'echo "export PATH=\$PATH:/usr/local/bin/geth" >> /etc/profile'

      if [ ! -f /lib/systemd/system/geth.service ]; then
         echo -n '   - creating geth.service file: '
         sudo /bin/bash -c 'cat << EOF > /lib/systemd/system/geth.service
[Unit]
Description=geth
After=network.target
[Service]
User=eth
Group=eth
ExecStart=/usr/local/bin/geth/geth --datadir=/mnt/ssd/datadir --cache 128 --syncmode fast --maxpeers 50 --light.maxpeers 10
KillMode=process
Restart=on-failure
RestartSec=60
[Install]
WantedBy=multi-user.target
EOF'
         echo 'OK'
      fi
   
      if [ ! -L /etc/systemd/system/geth.service ]; then
         sudo ln -s /lib/systemd/system/geth.service /etc/systemd/system/
      fi
   fi

   echo ''
   echo -n '   - creating symlink (to the latest geth version): '
   sudo ln -s ${TARGET} geth
   if [ $? -ne 0 ]; then
      echo 'error creating new link'
      exit 1
   fi
   echo 'OK'

   if [ "$GETH_RUNNING" = true ]; then
      echo -n '   - starting geth service'
      sudo systemctl start geth
   fi

   if [ "$1" = false ]; then
      echo ''
      echo ''
      echo 'To start geth: sudo systemctl start geth'
      echo 'To run geth on startup: sudo systemctl enable geth'
      echo ''
   fi

   echo ''
   echo "   geth $VERSION is here "
   echo ''

}

function show_help () {
   echo $0  'install or upgrade Ethereum geth'
   echo ''
   echo '   You must specify one argument:'
   echo '   -u    upgrade geth to the latest version'
   echo '   -i    install geth latest version'
   echo '   -h    print help (this message)'
   echo ''
}

if [ $# -ne 1 ]; then
   show_help
   exit 1
fi

if [ "$1" == '-u' ]; then
   UPGRADE=true
elif [ "$1" == '-i' ]; then
   UPGRADE=false
elif [ "$1" == '-h' ]; then
   show_help
   exit 0
else
   show_help
   exit 1
fi

echo 'Doing some basic checks...'
checks_common
if [ "$UPGRADE" = true ]; then
   checks4upgrade
fi

echo ''
echo 'Checking version:'
check_new_version
echo '   latest geth version: ' $NEWVER
if [ "$UPGRADE" = true ]; then
   echo '   current geth version:' $OLDVER
   compare_versions
fi

install_new_version $UPGRADE
