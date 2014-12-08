#!/bin/bash

setEcho() {
	Echo=""
	if [ -x "/bin/echo" ]; then
		Echo="/bin/echo -e"
	elif [ -x "`which printf`" ]; then
		Echo="`which printf` %b\n"
	else
		Echo="echo"
	fi

	#${Echo} "echo command is set to be '${Echo}'"
}

echo "loading script.bootstrap.functions.sh"



ValidateConfig() {
	# criteria for a valid config is:
	#  - populated attribute: installer_section0_buildComponentList and MUST contain one or both of 'eduroam' or 'shibboleth
	#  - non empty attributes for each set
	#
	# this parses all attributes in the configuration file to ensure they are not zero length
	#
	#
	#	Methodology: 
	#				enumerate and iterate over the field installer_section0_buildComponentList
	#				based on the features in there, assemble the required fields 
	#					iterate over each variable name and enforce non empty state, bail entirely if failed

	#  	the old check: - anything, but non empty: vc_attribute_list=`cat ${Spath}/config|egrep -v "^#"| awk -F= '{print $1}'|awk '/./'|tr '\n' ' '`
	
	vc_attribute_list=""

	# build our required field list dynamically

	eval set -- "${installer_section0_buildComponentList}"

	while [ $# -gt 0 ]
	do
			# uncomment next 3 echo lines to diagnose variable substitution
			# ${Echo} "DO======${tmpVal}===== ---- $1, \$$1, ${!1}"
		if [ "XXXXXX" ==  "${1}XXXXXX" ]
        	then
			# ${Echo} "##### $1 is ${!1}"
			# ${Echo} "########EMPTYEMPTY $1 is empty"
			${Echo} "NO COMPONENTS SELECTED FOR VALIDATION - EXITING IMMEDIATELY"
			exit

		else
			#debug ${Echo} "working on ${1}"
			tmpFV="requiredNonEmptyFields${1}"
			

			#debug ${Echo} "=============dynamic var: ${tmpFV}"


			vc_attribute_list="${vc_attribute_list} `echo "${!tmpFV}"`";

			#settingsHumanReadable=" ${settingsHumanReadable}  ${tmpString}:  ${!1}\n"
			#settingsHumanReadable="${settingsHumanReadable} ${cfgDesc[$1]}:  ${!1}\n"
		fi
	
		shift
	done
	
	#=======

	tmpBailIfHasAny=""

	#old: vc_attribute_list=`cat ${Spath}/config|egrep -v "^#"| awk -F= '{print $1}'|awk '/./'|tr '\n' ' '`
	
	# uses indirect reference for variable names. 
	
	# ${Echo} "======working with ${vc_attribute_list}"



	eval set -- "${vc_attribute_list}"
	while [ $# -gt 0 ]
	do
			# uncomment next 3 ${Echo} lines to diagnose variable substitution
			# ${Echo} "DO======${tmpVal}===== ---- $1, \$$1, ${!1}"
		if [ "XXXXXX" ==  "${!1}XXXXXX" ]
        	then
			# ${Echo} "##### $1 is ${!1}"
			# ${Echo} "########EMPTYEMPTY $1 is empty"
			tmpBailIfHasAny="${tmpBailIfHasAny} $1 "
		else
			# ${Echo} "ha"
			tmpString=" `echo "${cfgDesc[$1]}"`";
			tmpval=" `echo "${!1}"`";
			#settingsHumanReadable=" ${settingsHumanReadable}  ${tmpString}:  ${!1}\n"
			settingsHumanReadable="${settingsHumanReadable} ${cfgDesc[$1]}:  ${!1}\n"
		fi
	
		shift
	done
	#
	# announce and exit when attributes are non zero
	#
		if [ "XXXXXX" ==  "${tmpBailIfHasAny}XXXXXX" ]
		then
			${Echo} ""
		else
			${Echo} "\n\nDoing pre-flight check..\n"
			sleep 2;
			${Echo} "Discovered some required field as blank from file: ${Spath}/config\n"
			${Echo} " ${tmpBailIfHasAny}";
			echo ""	
			${Echo} "Please check out the file for the above empty attributes. If needed, regenerate from the config tool at ~/www/index.html\n\n"
			exit 1;
		fi

cat > ${freeradiusfile} << EOM
${settingsHumanReadable}
EOM

	# Set certificate variables
	certOrg="${freeRADIUS_svr_org_name}"
	certC="${freeRADIUS_svr_country}"
# 	certLongC="${freeRADIUS_svr_commonName}"
}

guessLinuxDist() {
	lsbBin=`which lsb_release 2>/dev/null`
	if [ -x "${lsbBin}" ]
	then
		dist=`lsb_release -i 2>/dev/null | cut -d':' -f2 | sed -re 's/^\s+//g'`
	fi

	if [ ! -z "`${Echo} ${dist} | grep -i 'ubuntu' | grep -v 'grep'`" ]
	then
		dist="ubuntu"
	elif [ ! -z "`${Echo} ${dist} | grep -i 'redhat' | grep -v 'grep'`" ]
	then
		dist="redhat"
	elif [ -s "/etc/centos-release" ]
	then
		dist="centos"
	elif [ -s "/etc/redhat-release" ]
	then
		dist="redhat"
	else
		really=$(askYesNo "Distribution" "Can not guess linux distribution, procede assuming ubuntu(ish)?")

		if [ "${really}" != "n" ]
		then
			dist="ubuntu"
		else
			cleanBadInstall
		fi
	fi
}

validateConnectivity()

{

##############################
# variables definition
##############################
distr_install_nc='yum install -y nc'
distr_install_ldaptools='yum install -y openldap-clients'

##############################
# functions definition
##############################
function elo () {
        # execute log and output
        $1 | tee -a ${statusFile}
}

function el () {
        # execute and log
        ${Echo} "$1" >> ${statusFile}
        $1 &>> ${statusFile}
}

##############################
# install additional packages
##############################
elo "${Echo} ---------------------------------------------"
elo "${Echo} Installing additional software..."
el "$distr_install_nc"
el "$distr_install_ldaptools"
elo "${Echo} Validating ${ldapserver} reachability..."

##############################
# PING test
##############################
elo "${Echo} PING testing..."

${Echo} "ping -c 4 ${ldapserver}" >> ${statusFile}

# create pipe to avoid 'while read' limitations
if [ -e "mypipe" ]
then
  rm -f mypipe
fi
mkfifo mypipe
ping -c 4 ${ldapserver} > mypipe &

while read pong 
do
  ${Echo} $pong | tee -a ${statusFile}
  FF=$(${Echo} $pong | grep "packet" | awk '{print $6}')
  if [ ! -z $FF ]
        then DD=$FF
  fi
done < mypipe
rm -f mypipe
if [ ! -z $DD ]
then
  if [ $DD == "0%" ]
    then
        elo "${Echo} ping - - - - ok"
        PING="ok"
  elif [ $DD == "100%" ]
    then
        elo "${Echo} Ping - - - - failed"
        PING="failed"
  elif [ $DD == "25%" -o $DD == "50%" -o $DD == "75%" ]
    then
        elo "${Echo} Ping - - - - intermittent"
        PING="warning"
    else
        elo "${Echo} Ping - - - - failed"
        PING="failed"
  fi
else
        elo "${Echo} Ping - - - - failed"
        PING="failed"
fi

##############################
# port availabilty check
##############################
elo "${Echo} Port availability checking..."

el "nc -z -w5 ${ldapserver} 636 "
  if [ $? == "0" ]
    then
        elo "${Echo} port 636 - - - - ok"
        PORT636="ok"
    else
        elo "${Echo} port 636 - - - - failed"
        PORT636="failed"
  fi

el "nc -z -w5 ${ldapserver} 389"
  if [ $? == "0" ]
    then
        elo "${Echo} port 389 - - - - ok"
        PORT389="ok"
    else
        elo "${Echo} port 389 - - - - failed"
        PORT389="failed"
  fi

#############################
# retrive certificate
#############################

if [ $PORT636 == "ok" ]
    then
        elo "${Echo} Trying retrieve certificate..."
        ${Echo} "${Echo} | openssl s_client -connect ${ldapserver}:636 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | openssl x509 -noout -subject -dates -issuer" >> ${statusFile}
	chk=$(${Echo} | openssl s_client -connect ${ldapserver}:636 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | openssl x509 -noout -subject -dates -issuer)
        if [ $? == "0" ]
          then
		if [ ! -z "${chk}" ] 
		then
		${Echo} "${chk}" | tee -a ${statusFile}
		enddate=$(${Echo} "${chk}" | grep notAfter | awk -F"=" '{print $2}' )
                	  cert=$(date --date="$enddate" +%s)
                	  now=$(date +%s)
                	  nowexp=$(date -d "+30 days" +%s)

                	  if [ $cert -lt $now ]
                	    then
				elo "${Echo} certificate check - - - - failed"
                	      	elo "${Echo} ERROR: Certificate expired!"
                	      	CERTIFICATE="failed"
                	    else
				elo "${Echo} certificate check - - - - ok"
                	      	elo "${Echo} Certificate still valid"
				CERTIFICATE="ok"
                	  fi

                	  if [ $cert -lt $nowexp ]
                	    then
				elo "${Echo} certificate check - - - - warning"
                	      	elo "${Echo} WARNING: certificate will expire soon"
                	      	CERTIFICATE="warning"
                	  fi
		else
			elo "${Echo} certificate check - - - - failed"
                        CERTIFICATE="failed"
		fi
          else
                elo "${Echo} certificate check - - - - failed"
                CERTIFICATE="failed"
        fi
    else
        elo "${Echo} Port 636 is closed. Cancel certificate check"
        CERTIFICATE="failed"
fi

##############################
# bind LDAP user
##############################
elo "${Echo} LDAP bind checking...(might take few minutes)"
${Echo} "TLS_REQCERT ALLOW" > /root/.ldaprc
${Echo} "ldapwhoami -vvv -H ldaps://${ldapserver} -D \"${ldapbinddn}\" -x -w \"<removed>\"" >> ${statusFile}
ldapwhoami -vvv -H ldaps://${ldapserver} -D "${ldapbinddn}" -x -w "${ldappass}" &>> ${statusFile}
  if [ $? == "0" ]
    then
        elo "${Echo} ldap bind - - - - ok"
        LDAP="ok"
    else
        elo "${Echo} ldap bind - - - - failed"
        LDAP="failed"
  fi

##############################
# ntp server check
##############################
elo "${Echo} Validating ntpserver (${ntpserver}) reachability..."
${Echo} "ntpdate ${ntpserver}" >> ${statusFile}
ntpcheck=$(ntpdate ${ntpserver} 2>&1 | tee -a ${statusFile} | awk -F":" '{print $4}' | awk '{print $1 $2}')

if [ $ntpcheck == "noserver"  ]
        then
                elo "${Echo} ntpserver - - - - failed"
                NTPSERVER="failed"
        else
                elo "${Echo} ntpserver - - - - ok"
                NTPSERVER="ok"
fi
###############################
# summary results
###############################
elo "${Echo} ---------------------------------------------"
${Echo} "Summary:"
${Echo} "PING        - $PING"
${Echo} "PORT636     - $PORT636"
${Echo} "PORT389     - $PORT389"
${Echo} "CERTIFICATE - $CERTIFICATE"
${Echo} "LDAP        - $LDAP"
${Echo} "NTPSERVER   - $NTPSERVER"
elo "${Echo} ---------------------------------------------"

###############################
# pause and warning message
###############################
if [ $CERTIFICATE == "failed" -o $LDAP == "failed" ]
        then
                MESSAGE="[ERROR] Reachability test has been failed. Installation will exit [press Enter key]: "
                ${Echo} -n $MESSAGE
                read choice
                if [ ! -z $choice ]
                then
                        if [ $choice != "continue" ]
                                then
                                        ${Echo} "Installation has been canceled."
                                        exit 1
                        fi
                else
                        ${Echo} "Installation has been canceled."
                        exit 1
                fi
elif [ $PING == "failed" -o $PING == "warning" -o $PORT389 == "failed" -o $CERTIFICATE == "warning" -o $NTPSERVER == "failed" ];
        then
                MESSAGE="[WARNING] Reachability test completed with some uncritical exceptions. Do you want to continue? [Y/n] "
                ${Echo} -n $MESSAGE
                read choice
                if [ ! -z $choice ]
                then
                        if [ $choice == "Y" -o $choice == "y" -o $choice == "yes" ]
                                then
                                        ${Echo} "Continue..."
                                else
                                        ${Echo} "Installation has been canceled."
                                        exit 1
                        fi
                else
                        ${Echo} "Continue..."
                fi
        else
                MESSAGE="[SUCCESS] Reachability test has been completed successfully. [press Enter to continue] "
                ${Echo} -n $MESSAGE
                read choice
fi

${Echo} "Starting installation script..."


}

