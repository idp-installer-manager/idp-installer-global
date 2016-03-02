#!/bin/bash
# UTF-8


HELP="




##############################################################################
#  Federated Identity Deployer Tools script by:                              #
# Anders Lördal,  SWAMID                                                     #
# Chris Phillips, CANARIE                                                    #
#                                                                            #
#                                                                            #
# Version 2.6                                                                #
#                                                                            #
# Deploys a working IDP for SWAMID on an Ubuntu, CentOS or Redhat system     #
# SAML2 Uses: tomcat6                                                        #
#       shibboleth-identityprovider-2.4.0                                    #
#       cas-client-3.2.1-release                                             #
#       mysql-connector-java-5.1.27 (for EPTID)                              #
#       apache-maven-3.1.1 (for building FTICKS plugin)                      #
# eduroam uses:                                                              #
#       freeRADIUS-2.1.12                                                    #
#       samba-3.6.9 (to connect to AD for MS-CHAPv2)                         #
#                                                                            #
# Templates are provided for CAS and LDAP authentication                     #
#                                                                            #
# To disable the whiptail gui run with argument '-c'                         #
# To keep generated files run with argument '-k'                             #
#    NOTE! some of theese files WILL contain cleartext passwords.            #
#                                                                            #
# To add a new template for another authentication, just add a new directory #
# under the 'prep' directory, add the neccesary .diff files and add any      #
# special hanlding of those files to the script.                             #
#                                                                            #
# You can pre-set configuration values in the file 'config'                  #
#                                                                            #
# Please send questions and improvements to: anders.lordal@hig.se            #
##############################################################################
"

# Copyright 2011, 2012, 2013, 2014
# Anders Lördal, SWAMID
# Chris Phillips, CANARIE
#
#
# This file is part of IDP-Deployer
#
# IDP-Deployer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# IDP-Deployer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with IDP-Deployer. If not, see <http://www.gnu.org/licenses/>.

if [ "${USERNAME}" != "root" -a "${USER}" != "root" ]; then
	echo "Run as root!"
	exit
fi

Spath="$(cd "$(dirname "$0")" && pwd)"

# load boostrap functions needed early on in this process
. ${Spath}/files/script.messages.sh
. ${Spath}/files/script.bootstrap.functions.sh
setEcho
# (validateConfig)
guessLinuxDist
setDistCommands

${Echo} "\n\n\nStarting up.\n\n\n"
${Echo} "Live logging can be seen by this command in another window:\ntail -f ${statusFile}"
${Echo} "Sleeping for 4 sec and then beginning processing..."
${Echo} "==============================================================================="
sleep 4
# bootstrapping step from minimal install
#
# bindutils to get the basic host info from machine
# dos2unix to ensure we have a clean include of hand managed files
#

if [ ! -f "/usr/bin/host" -o ! -f "/usr/bin/dos2unix" ]; then
	${Echo} "\nAdding a few packages that we will use during the installation process..."
	${Echo} "Package updates on the machine which could take a few minutes."
	if [ "${dist}" = "ubuntu" ]; then
		apt-get -y install dos2unix &> >(tee -a ${statusFile})
	else
		yum -y install bind-utils net-tools ntpdate dos2unix &> >(tee -a ${statusFile})
	fi
fi

# read config file as early as we can so we may use the variables
# use dos2unix on file first however in case it has some mad ^M in it

if [ -s "${Spath}/config" ]
then
	dos2unix ${Spath}/config
	. ${Spath}/config		# dynamically (or by hand) editted config file
	. ${Spath}/config_descriptions	# descriptive terms for each element - uses associative array cfgDesc[varname]

	ValidateConfig

	if [ -z "${installer_interactive}" ]
	then
		installer_interactive="y"
	fi

	if echo "${installer_section0_buildComponentList}" | grep -q "shibboleth"; then
		validateConnectivity ${installer_section0_version}

		checkEptidDb
	fi

else
	${Echo} "Sorry, this tool requires a configuration file to operate properly. \nPlease use ~/wwww/appconfig/<your_federation>/index.html to create one. Now exiting"
	exit

fi


. ${Spath}/files/script.functions.sh
. ${Spath}/files/script.eduroam.functions.sh


# import the federation override file. It must exist even if it is empty.
federationSpecificInstallerOverrides="${Spath}/files/${my_ctl_federation}/script.override.functions.sh"

if [ -f "${federationSpecificInstallerOverrides}" ]
then
	${Echo} "Adding federation specific overrides for the install process from ${federationSpecificInstallerOverrides}" >> ${statusFile} 2>&1
	. ${federationSpecificInstallerOverrides}
else
	${Echo} "\n\nNo federation specific overrides detected for federation: ${my_ctl_federation} (if this was blank, the config file does not contain BASH variable my_ctl_federation)"
	${Echo} "\n\nIf there was a value set, but no override file exists, then this installer may be incomplete for that federation. \nPlease refer to the developer docs in ~/docs, exiting now" 
	exit
fi








setBackTitle


# parse options
options=$(getopt -o ckh -l "help" -- "$@")
eval set -- "${options}"
while [ $# -gt 0 ]; do
	case "$1" in
		-c)
			GUIen="n"
		;;
		-k)
			cleanUp="0"
		;;
		-h | --help)
			${Echo} "${HELP}"
			exit
		;;
	esac
	shift
done

$Echo "" >> ${statusFile}

#################################
#################################

#setDistCommands
setHostnames




setInstallStatus


while [ "${mainMenuExitFlag}" -eq 0 ]; do

	displayMainMenu

done




#################################
#################################



cleanupFilesRoutine




notifyUserBeforeExit
showAndCleanupMessagesFile
