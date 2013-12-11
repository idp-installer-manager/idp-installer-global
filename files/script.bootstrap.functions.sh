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

	${Echo} "echo command is set to be '${Echo}'"
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
			# echo "DO======${tmpVal}===== ---- $1, \$$1, ${!1}"
		if [ "XXXXXX" ==  "${1}XXXXXX" ]
        	then
			# echo "##### $1 is ${!1}"
			# echo "########EMPTYEMPTY $1 is empty"
			echo "NO COMPONENTS SELECTED FOR VALIDATION - EXITING IMMEDIATELY"
			exit

		else
			echo "working on ${1}"
			tmpFV="requiredNonEmptyFields${1}"
			

			echo "=============dynamic var: ${tmpFV}"


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
	
	# echo "======working with ${vc_attribute_list}"



	eval set -- "${vc_attribute_list}"
	while [ $# -gt 0 ]
	do
			# uncomment next 3 echo lines to diagnose variable substitution
			# echo "DO======${tmpVal}===== ---- $1, \$$1, ${!1}"
		if [ "XXXXXX" ==  "${!1}XXXXXX" ]
        	then
			# echo "##### $1 is ${!1}"
			# echo "########EMPTYEMPTY $1 is empty"
			tmpBailIfHasAny="${tmpBailIfHasAny} $1 "
		else
			#echo "ha"
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
			echo ""
		else
			echo -e "\n\nDoing pre-flight check..\n"
			sleep 2;
			echo -e "Discovered some required field as blank from file: ${Spath}/config\n"
			echo -e " ${tmpBailIfHasAny}";
			echo ""	
			echo -e "Please check out the file for the above empty attributes. If needed, regenerate from the config tool at ~/www/index.html\n\n"
			exit 1;
		fi

cat > ${freeradiusfile} << EOM
${settingsHumanReadable}
EOM

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

