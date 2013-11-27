#!/bin/sh

if [ "${USERNAME}" != "root" ]
then
	echo "Run as root!"
	exit
fi

apt-get update
apt-get -qq -y install `egrep "apt-get .+install" deploy_idp.sh |awk -F'install ' '{print $2}' |perl -npe 's/\ /\n/g' |sort -u | perl -npe 's/\n/\ /g'`

