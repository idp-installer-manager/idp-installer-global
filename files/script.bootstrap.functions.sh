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
		really=$(askYesNo "Distribution" "Can not guess linux distribution, procede assuming debian(ish)?")

		if [ "${really}" != "n" ]
		then
			dist="ubuntu"
		else
			cleanBadInstall
		fi
	fi
}

setDistCommands() {
        if [ ${dist} = "ubuntu" ]; then
		redhatDist="none"
		debianDist=`cat /etc/issue.net | awk -F' ' '{print $2}'  | cut -d. -f1`
                distCmdU=${ubuntuCmdU}
                distCmdUa=${ubuntuCmdUa}
                distCmd1=${ubuntuCmd1}
                distCmd2=${ubuntuCmd2}
                distCmd3=${ubuntuCmd3}
                distCmd4=${ubuntuCmd4}
                distCmd5=${ubuntuCmd5}
                tomcatSettingsFile=${tomcatSettingsFileU}
                dist_install_nc=${ubutnu_install_nc}
                dist_install_ldaptools=${ubuntu_install_ldaptools}
                distCmdEduroam=${ubuntuCmdEduroam}
		distEduroamPath=${ubuntuEduroamPath}
		distRadiusGroup=${ubuntuRadiusGroup}
		templatePathEduroamDist=${templatePathEduroamUbuntu}
		distEduroamModules=${UbuntuEduroamModules}
        elif [ ${dist} = "centos" -o "${dist}" = "redhat" ]; then
                if [ ${dist} = "centos" ]; then
			redhatDist=`rpm -q centos-release | awk -F'-' '{print $3}'`
                        #redhatDist=`cat /etc/centos-release |cut -f3 -d' ' |cut -c1`
                        distCmdU=${centosCmdU}
                        distCmdUa=${centosCmdUa}
                        distCmd1=${centosCmd1}
                        distCmd2=${centosCmd2}
                        distCmd3=${centosCmd3}
                        distCmd4=${centosCmd4}
                        distCmd5=${centosCmd5}
                        wget vim gcc openssl-devel unzip libnl-devel yum-cron
                        dist_install_nc=${centos_install_nc}
                        dist_install_netstat=${centos_install_netstat}
                        dist_install_ldaptools=${centos_install_ldaptools}
                        distCmdEduroam=${centosCmdEduroam}
			distEduroamPath=${centosEduroamPath}
			distRadiusGroup=${centosRadiusGroup}
			if [ ${redhatDist} = "7"  ]; then
				templatePathEduroamDist=${templatePathEduroamCentOS7}
				distEduroamModules=${CentOS7EduroamModules}
			else
				templatePathEduroamDist=${templatePathEduroamCentOS}
				distEduroamModules=${CentOSEduroamModules}
			fi
                else
                        redhatDist=`cat /etc/redhat-release | cut -d' ' -f7 | cut -c1`
                        distCmdU=${redhatCmdU}
                        distCmd1=${redhatCmd1}
                        distCmd2=${redhatCmd2}
                        distCmd3=${redhatCmd3}
                        distCmd4=${redhatCmd4}
                        distCmd5=${redhatCmd5}
                        dist_install_nc=${redhat_install_nc}
                        dist_install_netstat=${redhat_install_netstat}
                        dist_install_ldaptools=${redhat_install_ldaptools}
                        distCmdEduroam=${redhatCmdEduroam}
			distEduroamPath=${redhatEduroamPath}
			distRadiusGroup=${redhatRadiusGroup}
			templatePathEduroamDist=${templatePathEduroamRedhat}
			distEduroamModules=${RedhatEduroamModules}
                fi
                tomcatSettingsFile=${tomcatSettingsFileC}

                if [ "$redhatDist" -eq "6" ]; then
                        redhatEpel=${redhatEpel6}
                else
                        redhatEpel=${redhatEpel5}
                fi

        fi
}


validateConnectivity()

{
	if [ "$1" == "test" ]; then return 0; fi 
	##############################
	# variables definition
	##############################
	#distr_install_nc='yum install -y nc'
	#distr_install_ldaptools='yum install -y openldap-clients'

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
	elo "$dist_install_nc"
	elo "$dist_install_netstat"
	elo "$dist_install_ldaptools"

	##############################
	# ntp server check
	##############################
	elo "${Echo} Validating ntpserver (${ntpserver}) reachability..."
	${Echo} "ntpdate ${ntpserver}" &> >(tee -a ${statusFile})
	ntpcheck=$(ntpdate ${ntpserver} 2>&1 | head -n1 | awk '{print $1 $2}')
	if [ $ntpcheck == "Errorresolving" ]
		then
			elo "${Echo} ntpserver - - - - failed"
			NTPSERVER="failed"
		else
		ntpcheck=$(ntpdate ${ntpserver} 2>&1 | head -n1 | awk -F":" '{print $4}' | awk '{print $1 $2}')
		if [ $ntpcheck == "adjusttime"  ]
			then
				elo "${Echo} ntpserver - - - - ok"
				NTPSERVER="ok"
			else
				elo "${Echo} ntpserver - - - - failed"
				NTPSERVER="failed"
		fi
	fi

	elo "${Echo} Validating ${ldapserver} reachability..."
	serverCounter=0
	declare -A serverResults
	for server in ${ldapserver}; do
		serverResults[${serverCounter},0]=$server
		##############################
		# PING test
		##############################
		elo "${Echo} PING testing..."

		${Echo} "ping -c 4 $server" >> ${statusFile}

		# create pipe to avoid 'while read' limitations
		if [ -e "mypipe" ]; then
			rm -f mypipe
		fi
		mkfifo mypipe
		ping -c 4 $server > mypipe &

		while read pong; do
			${Echo} $pong | tee -a ${statusFile}
			FF=$(${Echo} $pong | grep "packet" | awk '{print $6}')
			if [ ! -z $FF ]; then
				DD=$FF
			fi
		done < mypipe
		rm -f mypipe
		if [ ! -z $DD ]; then
			if [ $DD == "0%" ]; then
				elo "${Echo} ping - - - - ok"
				PING="ok"
			elif [ $DD == "100%" ]; then
				elo "${Echo} Ping - - - - failed"
				PING="failed"
			elif [ $DD == "25%" -o $DD == "50%" -o $DD == "75%" ]; then
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
		serverResults[${serverCounter},1]=$PING

		##############################
		# port availabilty check
		##############################
		elo "${Echo} Port availability checking..."

		output=$(nc $server 636 < /dev/null 2>&1)
		if [ $? -eq 0 ] || echo "${output}" | grep -q "Connection reset by peer"; then
			elo "${Echo} port 636 - - - - ok"
			PORT636="ok"
		else
			elo "${Echo} port 636 - - - - failed"
			PORT636="failed"
		fi
		serverResults[${serverCounter},2]=$PORT636

		output=$(nc $server 389 < /dev/null 2>&1)
		if [ $? -eq 0 ] || echo "${output}" | grep -q "Connection reset by peer"; then
			elo "${Echo} port 389 - - - - ok"
			PORT389="ok"
		else
			elo "${Echo} port 389 - - - - failed"
			PORT389="failed"
		fi
		serverResults[${serverCounter},3]=$PORT389

		#############################
		# retrive certificate
		#############################

		if [ ${serverResults[${serverCounter},2]} == "ok" ]; then
			elo "${Echo} Trying retrieve certificate..."
			${Echo} "${Echo} | openssl s_client -connect $server:636 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | openssl x509 -noout -subject -dates -issuer" >> ${statusFile}
			chk=$(${Echo} | openssl s_client -connect $server:636 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' | openssl x509 -noout -subject -dates -issuer)
			if [ $? == "0" ]; then
				if [ ! -z "${chk}" ]; then
				${Echo} "${chk}" | tee -a ${statusFile}
				enddate=$(${Echo} "${chk}" | grep notAfter | awk -F"=" '{print $2}' )
					cert=$(date --date="$enddate" +%s)
					now=$(date +%s)
					nowexp=$(date -d "+30 days" +%s)

					if [ $cert -lt $now ]; then
						elo "${Echo} certificate check - - - - failed"
						elo "${Echo} ERROR: Certificate expired!"
						CERTIFICATE="failed"
					else
						elo "${Echo} certificate check - - - - ok"
						elo "${Echo} Certificate still valid"
						CERTIFICATE="ok"
					fi

					if [ $cert -lt $nowexp ]; then
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
		serverResults[${serverCounter},4]=$CERTIFICATE

		##############################
		# bind LDAP user
		##############################
		elo "${Echo} LDAP bind checking...(might take few minutes)"
		if [ -z "`grep 'TLS_REQCERT' /root/.ldaprc 2>/dev/null`" ]; then
			${Echo} "TLS_REQCERT ALLOW" >> /root/.ldaprc
		fi
		ldapBaseDN=`echo ${ldapbinddn} | cut -d, -f2-`
		ldapSearchValue=`echo ${ldapbinddn} | cut -d, -f1`
		${Echo} "ldapsearch -vvv -H ldaps://$server -D \"${ldapbinddn}\" -b \"${ldapBaseDN}\" -x -w \"<removed>\" \"${ldapSearchValue}\"" >> ${statusFile}
		ldapsearch -vvv -H ldaps://$server -D "${ldapbinddn}" -b "${ldapBaseDN}" -x -w "${ldappass}" "${ldapSearchValue}" &>> ${statusFile}
		if [ $? == "0" ]; then
			elo "${Echo} ldap bind - - - - ok"
			LDAP="ok"
		else
			elo "${Echo} ldap bind - - - - failed"
			LDAP="failed"
		fi
		serverResults[${serverCounter},5]=$LDAP

		serverCounter=`expr ${serverCounter} + 1`
	done

	###############################
	# summary results
	###############################
	PING="ok"
	PORT636="ok"
	PORT389="ok"
	CERTIFICATE="ok"
	LDAP="ok"

	elo "${Echo} ---------------------------------------------"
	${Echo} "Summary:"
	arrayLength=`expr ${serverCounter} - 1`
	for ((i = 0; i <= $arrayLength; i++)); do
		${Echo} "Server      - ${serverResults[$i,0]}"
		${Echo} "PING        - ${serverResults[$i,1]}"
		${Echo} "PORT636     - ${serverResults[$i,2]}"
		${Echo} "PORT389     - ${serverResults[$i,3]}"
		${Echo} "CERTIFICATE - ${serverResults[$i,4]}"
		${Echo} "LDAP        - ${serverResults[$i,5]}"
		if [ "${serverResults[$i,1]}" != "ok" ]; then
			PING=${serverResults[$i,1]}
		fi
		if [ "${serverResults[$i,2]}" != "ok" ]; then
			PORT636=${serverResults[$i,2]}
		fi
		if [ "${serverResults[$i,3]}" != "ok" ]; then
			PORT389=${serverResults[$i,3]}
		fi
		if [ "${serverResults[$i,4]}" != "ok" ]; then
			CERTIFICATE=${serverResults[$i,4]}
		fi
		if [ "${serverResults[$i,5]}" != "ok" ]; then
			LDAP=${serverResults[$i,5]}
		fi
		${Echo} ""
	done
	${Echo} "NTPSERVER   - $NTPSERVER"
	elo "${Echo} ---------------------------------------------"

	###############################
	# pause and warning message
	###############################
	if [ $CERTIFICATE == "failed" -o $LDAP == "failed" ]; then
		MESSAGE="[ERROR] Reachability test has been failed. Installation will exit [press Enter key]: "
		${Echo} -n $MESSAGE
		if [ "${installer_interactive}" = "y" ]; then
			read choice
		fi
		if [ ! -z $choice ]; then
			if [ $choice != "continue" ]
				then
					${Echo} "Installation has been canceled."
					exit 1
			fi
		else
			${Echo} "Installation has been canceled."
			exit 1
		fi
	elif [ $PING == "failed" -o $PING == "warning" -o $PORT389 == "failed" -o $CERTIFICATE == "warning" -o $NTPSERVER == "failed" ]; then
		MESSAGE="[WARNING] Reachability test completed with some uncritical exceptions. Do you want to continue? [Y/n] "
		${Echo} -n $MESSAGE
		if [ "${installer_interactive}" = "y" ]; then
			read choice
		fi
		if [ ! -z $choice ]; then
			if [ $choice == "Y" -o $choice == "y" -o $choice == "yes" ]; then
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
		if [ "${installer_interactive}" = "y" ]; then
			read choice
		fi
	fi

	${Echo} "Starting installation script..."

}



checkEptidDb() {
    if [ "${eptid}" = "n" ]; then
	return 0
    fi

    ${Echo} "Checking for existing EPTID database..."
    if [ ! -f /etc/init.d/mysqld ]; then
	${Echo} "MySQL not installed, skipping"
	return 0
    fi

    if [ ! -f /opt/shibboleth-idp/conf/attribute-resolver.xml ]; then
	mysql --no-defaults -uroot --password="" -e "" > /dev/null 2>&1

	if [ $? -ne 0 ]; then
	    ${Echo} "ERROR: Existing EPTID configuration not found but MySQL root password is set. Please remove the MySQL root password then try again."
	    exit 1
	fi

	return 0
    fi

    ${Echo} "/opt/shibboleth/conf/attribute-resolver exists, installer will use existing salt and password"

    epass=$(grep jdbcPassword /opt/shibboleth-idp/conf/attribute-resolver.xml | grep -v 'jdbcPassword="mypassword"' | awk -F '"' '{print $2}')
    esalt=$(grep salt /opt/shibboleth-idp/conf/attribute-resolver.xml | grep -v 'salt="your random string here"' | awk -F '"' '{print $2}')

    if [ -z "${epass}" ]; then
	${Echo} "ERROR: Could not retrieve MySQL password from attribute-resolver.xml"
	exit 1
    fi
    
    if [ -z "${esalt}" ]; then
	${Echo} "ERROR: Could not retrieve salt from attribute-resolver.xml"
	exit 1
    fi

    ${Echo} "Testing existing MySQL password..."
    mysql --no-defaults -ushibboleth --password="${epass}" -e "" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        ${Echo} "ERROR: Failed to connect to MySQL using user 'shibboleth' and password from /opt/shibboleth-idp/conf/attribute-resolver.xml. Please correct the password in attribute-resolver.xml or remove the file entirely if the EPTID table needs to be created."
        exit 1
    fi

    ${Echo} "MySQL password works!"
}
