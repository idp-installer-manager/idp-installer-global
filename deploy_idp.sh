#!/bin/sh -x
# UTF-8
HELP="
##############################################################################
# Shibboleth deployment script by Anders Lördal                              #
# Högskolan i Gävle and SWAMID                                               #
#                                                                            #
# Version 2.5                                                                #
#                                                                            #
# Deploys a working IDP for SWAMID on an Ubuntu, CentOS or Redhat system     #
# Uses: tomcat6                                                              #
#       shibboleth-identityprovider-2.4.0                                    #
#       cas-client-3.2.1-release                                             #
#       mysql-connector-java-5.1.26 (for EPTID)                              #
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

# Copyright 2011, 2012, 2013 Anders Lördal, Högskolan i Gävle and SWAMID
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
	$Echo "Run as root!"
	exit
fi

# bootstrapping step from minimal install
#
# bindutils to get the basic host info from machine
# dos2unix to ensure we have a clean include of hand managed files
#

if [ -f "/usr/bin/host" -a -f "/usr/bin/dos2unix" ]
then
	# we do nothing, just making sure it's there
	echo ""
else
	echo -e "\n\nAdding a few packages that we will use during the installation process..."
	sleep 3;
	yum -y install bind-utils dos2unix

fi


Spath="$(cd "$(dirname "$0")" && pwd)"
. ${Spath}/files/script.messages.sh
. ${Spath}/files/script.functions.sh
. ${Spath}/files/script.eduroam.functions.sh

setEcho



# read config file as early as we can so we may use the variables
# use dos2unix on file first however in case it has some mad ^M in it

if [ -f "${Spath}/config" ]
then
	dos2unix ${Spath}/config
	. ${Spath}/config		# dynamically (or by hand) editted config file
	. ${Spath}/config_descriptions	# descriptive terms for each element - uses associative array cfgDesc[varname]
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

$Echo "" > ${statusFile}

#################################
#################################

# guess linux dist
guessLinuxDist
setDistCommands
setHostnames



validateConfig
setInstallStatus
displayMainMenu
createRestorePoint




#################################
#################################



cleanupFilesRoutine




notifyUserBeforeExit
showAndCleanupMessagesFile
