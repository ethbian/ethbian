#!/bin/bash

echo ''
echo '*****************************************'
echo '*       ETHBIAN GETH UPGRADE v0.1       *'
echo '*****************************************'
echo ''

INSTALLDIR='/usr/local/bin'
DOWNDIR='/tmp'
REPO='https://gethstore.blob.core.windows.net/builds/'
TARGET='geth-linux-arm7-VERSION-HASH'
GPGBUILDER='9BA28146'
GPGKEYSRV='keyserver.ubuntu.com'
TOOLS='readlink curl jq wget gpg tar'

echo -n 'Doing some basic checks: '
if [ ! -d $INSTALLDIR ]; then
   echo '   Installation directory does not exist.'
   exit 1
fi

cd $INSTALLDIR
if [ ! -L geth ]; then
   echo 'symlink geth in the installation directory does not exist.'
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
echo 'OK'

echo ''
LINK=`readlink geth`
OLDVER=v`echo $LINK| cut -f 4 -d "-"`
echo 'current geth version:' $OLDVER

NEWVER=`curl --silent 'https://api.github.com/repos/ethereum/go-ethereum/releases/latest' | jq -r .tag_name`
if [ $? -ne 0 ]; then
   echo 'something went wrong, try again later.'
   exit 1
fi
echo 'latest geth version: ' $NEWVER
echo ''

if [ "$OLDVER" == "$NEWVER" ]; then
   echo '   The latest geth version is already installed.'
   exit 0
fi

cd $DOWNDIR
echo 'Trying to download the files...'
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

echo -n '   - creating new symlink (to the latest geth version): '
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

echo ''
echo ''
echo "   geth $VERSION is here "
echo ''
