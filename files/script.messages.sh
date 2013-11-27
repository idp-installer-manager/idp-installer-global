#!/bin/sh
# UTF-8

mdSignerFinger="12:60:D7:09:6A:D9:C1:43:AD:31:88:14:3C:A8:C4:B7:33:8A:4F:CB"
GUIen=y
cleanUp=1
upgrade=0
shibVer="2.4.0"
casVer="3.2.1"
mysqlConVer="5.1.27"

files=""
ts=`date "+%s"`
whiptailBin=`which whiptail`
if [ ! -x "${whiptailBin}" ]
then
	GUIen="n"
fi

#
# used in eduroam configs
#
backupPath="${Spath}/backups/"
templatePath="${Spath}/assets"
backupList="${backupPath}/recoverypoints.txt"
freeradiusfile="${Spath}/files/freeradius.tx"


whipSize="13 75"
certpath="/opt/shibboleth-idp/ssl/"
httpsP12="/opt/shibboleth-idp/credentials/https.p12"
certREQ="${certpath}tomcat.req"
passGenCmd="openssl rand -base64 20"
messages="${Spath}/msg.txt"
statusFile="${Spath}/status.log"
bupFile="/opt/backup-shibboleth-idp.${ts}.tar.gz"
idpPath="/opt/shibboleth-idp/"
certificateChain="http://webkonto.hig.se/chain.pem"
tomcatDepend="https://build.shibboleth.net/nexus/content/repositories/releases/edu/internet2/middleware/security/tomcat6/tomcat6-dta-ssl/1.0.0/tomcat6-dta-ssl-1.0.0.jar"
dist=""
distCmdU=""
distCmd1=""
distCmd2=""
distCmd3=""
distCmd4=""
distCmd5=""
fetchCmd="curl --silent -k --output"
shibbURL="http://shibboleth.net/downloads/identity-provider/${shibVer}/shibboleth-identityprovider-${shibVer}-bin.zip"
casClientURL="http://downloads.jasig.org/cas-clients/cas-client-${casVer}-release.zip"
mysqlConnectorURL="http://ftp.sunet.se/pub/unix/databases/relational/mysql/Downloads/Connector-J/mysql-connector-java-${mysqlConVer}.tar.gz"
Rmsg="Do you want to install 'EPEL' and 'jpackage' to automaticly install dependancies? (Without theese depends the install WILL fail!)"

# Titles for the whiptail environment for branding
BackTitleSWAMID="SWAMID"
BackTitleCAF="Canadian Access Federation"
BackTitle="IDP Deployer"

# define commands
ubuntuCmdU="apt-get -qq update"
ubuntuCmd1="apt-get -y install patch ntpdate unzip curl >> ${statusFile} 2>&1"
ubuntuCmd2="apt-get -y install git-core maven2 openjdk-6-jdk >> ${statusFile} 2>&1"
ubuntuCmd3="apt-get -y install default-jre >> ${statusFile} 2>&1"
ubuntuCmd4="apt-get -y install tomcat6 >> ${statusFile} 2>&1"
ubuntuCmd5="apt-get -y install mysql-server >> ${statusFile} 2>&1"
tomcatSettingsFileU="/etc/default/tomcat6"

redhatCmdU="yum -y update"
redhatCmd1="yum -y install patch ntpdate unzip curl >> ${statusFile} 2>&1"
redhatCmd2="yum -y install git-core java-1.7.0-openjdk-devel >> ${statusFile} 2>&1"
redhatCmd3="yum -y install java-1.7.0-openjdk >> ${statusFile} 2>&1"
redhatCmd4="yum -y install tomcat6 >> ${statusFile} 2>&1"
redhatCmd5="yum -y install mysql-server >> ${statusFile} 2>&1"


redhatCmdEduroam="yum -y install bind-utils ntp samba samba-winbind freeradius freeradius-krb5 freeradius-ldap freeradius-perl freeradius-python freeradius-utils freeradius-mysql make" 
#redhatCmdFedSSO="yum -y install java-1.6.0-openjdk-devel tomcat6 mysql-server mysql"

centosCmdEduroam="yum -y install bind-utils ntp samba samba-winbind freeradius freeradius-krb5 freeradius-ldap freeradius-perl freeradius-python freeradius-utils freeradius-mysql make" 
centosCmdFedSSO="yum -y install java-1.6.0-openjdk-devel tomcat6 mysql-server mysql"

centosCmdU="yum -y update; yum clean all"
centosCmd1="yum -y install patch ntpdate unzip curl >> ${statusFile} 2>&1"
centosCmd2="yum -y install git java-1.7.0-openjdk-devel >> ${statusFile} 2>&1"
centosCmd3="yum -y install java-1.7.0-openjdk >> ${statusFile} 2>&1"
centosCmd4="yum -y install tomcat6 >> ${statusFile} 2>&1"
centosCmd5="yum -y install mysql-server >> ${statusFile} 2>&1"
tomcatSettingsFileC="/etc/sysconfig/tomcat6"

redhatEpel5="rpm -Uvh http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
redhatEpel6="rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm"

