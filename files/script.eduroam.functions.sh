#!/bin/sh
# UTF-8
setInstallStatus() {


# check for installed IDP
msg_FSSO="Federated SSO/Shibboleth:"
msg_RADIUS="eduroam read FreeRADIUS:"

if [ -L "/opt/shibboleth-identityprovider" -a -d "/opt/shibboleth-idp" ]
then
        msg_fsso_stat="Installed"
	installStateFSSO=1
else
	msg_fsso_stat="Not Installed yet"
	installStateFSSO=0
fi

if [ -L "/etc/raddb/sites-enabled/eduroam-inner-tunnel" -a -d "/etc/raddb" ]
then
        msg_freeradius_stat="Installed"
	installStateEduroam=1
else
        msg_freeradius_stat="Not Installed yet"
	installStateEduroam=0
fi
getStatusString="System state:\n${msg_FSSO} ${msg_fsso_stat}\n${msg_RADIUS} ${msg_freeradius_stat}"

}

refresh() {
			
			${whiptailBin} --backtitle "${GUIbacktitle}" --title "Deploy/Refresh relevant eduroam software base" --defaultno --yes-button "Yes, proceed" --no-button "No, back to main menu" --yesno --clear -- \
                        "Create restore point and refresh machine to CAF eduroam base?" ${whipSize} 3>&1 1>&2 2>&3
                	continueFwipe=$?
                	if [ "${continueFwipe}" -eq 0 ]
                	then
				eval ${redhatCmdEduroam}	
				echo ""
				echo "Update Completed" >> ${statusFile} 2>&1 
                	fi
			
			displayMainMenu

}
review(){

 if [ "${GUIen}" = "y" ]
                then
                        ${whiptailBin} --backtitle "${GUIbacktitle}" --title "Review Install Settings" --ok-button "Return to Main Menu" --scrolltext --clear --textbox ${freeradiusfile} 20 75 3>&1 1>&2 2>&3

		displayMainMenu

                else
			echo "Please make sure whiptail is installed"
                fi


}

modifyIPTABLESForEduroam ()
{
	{Echo} "Updating IPTABLES configuration to permit eduroam UDP ports, 1812,1813,1814 to be accepted"

iptables -A INPUT -m udp -p udp --dport 1812 -j ACCEPT
iptables -A INPUT -m udp -p udp --dport 1813 -j ACCEPT
iptables -A INPUT -m udp -p udp --dport 1814 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

}

deployEduroamCustomizations() {
	
	# flat copy of files from deployer to OS
	
	cp ${templatePath}/etc/nsswitch.conf.template /etc/nsswitch.conf

	cp ${templatePath}/etc/raddb/sites-available/default.template /etc/raddb/sites-available/default
	cp ${templatePath}/etc/raddb/sites-available/eduroam.template /etc/raddb/sites-available/eduroam
	cp ${templatePath}/etc/raddb/sites-available/eduroam-inner-tunnel.template /etc/raddb/sites-available/eduroam-inner-tunnel
	cp ${templatePath}/etc/raddb/eap.conf.template /etc/raddb/eap.conf
	chgrp radiusd /etc/raddb/sites-available/*
	
	# remove and redo symlink for freeRADIUS sites-available to sites-enabled

(cd /etc/raddb/sites-enabled;rm -f eduroam-inner-tunnel; ln -s ../sites-available/eduroam-inner-tunnel eduroam-inner-tunnel)
(cd /etc/raddb/sites-enabled;rm -f eduroam; ln -s ../sites-available/eduroam)
	#rm -f /etc/raddb/sites-available/eduroam-inner-tunnel
	#ln -s /etc/raddb/sites-available/eduroam-inner-tunnel /etc/raddb/sites-enabled/eduroam-inner-tunnel
	#rm -f /etc/raddb/sites-available/eduroam
	#ln -s /etc/raddb/sites-available/eduroam /etc/raddb/sites-enabled/eduroam

	# do parsing of templates into the right spot
	# in order as they appear in the variable list
	
# /etc/krb5.conf	
	cat ${templatePath}/etc/krb5.conf.template \
	|perl -npe "s#kRb5_LiBdEf_DeFaUlT_ReAlM#${krb5_libdef_default_realm}#" \
	|perl -npe "s#kRb5_DoMaIn_ReAlM#${krb5_domain_realm}#" \
	|perl -npe "s#kRb5_rEaLmS_dEf_DoM#${krb5_realms_def_dom}#" \
	> /etc/krb5.conf

# /etc/samba/smb.conf
	cat ${templatePath}/etc/samba/smb.conf.template \
	|perl -npe "s#sMb_WoRkGrOuP#${smb_workgroup}#" \
	|perl -npe "s#sMb_NeTbIoS_NaMe#${smb_netbios_name}#" \
	|perl -npe "s#sMb_PaSsWd_SvR#${smb_passwd_svr}#" \
	|perl -npe "s#sMb_ReAlM#${smb_realm}#" \
	> /etc/samba/smb.conf

# /etc/raddb/modules
	cat ${templatePath}/etc/raddb/modules/mschap.template \
	|perl -npe "s#fReErAdIuS_rEaLm#${freeRADIUS_realm}#" \
	|perl -npe "s#PXYCFG_rEaLm#${freeRADIUS_pxycfg_realm}#" \
	 > /etc/raddb/modules/mschap
	chgrp radiusd /etc/raddb/modules/mschap

# /etc/raddb/radiusd.conf
	cat ${templatePath}/etc/raddb/radiusd.conf.template \
	|perl -npe "s#fReErAdIuS_rEaLm#${freeRADIUS_realm}#" \
	> /etc/raddb/radiusd.conf
	chgrp radiusd /etc/raddb/radiusd.conf

# /etc/raddb/proxy.conf
	cat ${templatePath}/etc/raddb/proxy.conf.template \
	|perl -npe "s#fReErAdIuS_rEaLm#${freeRADIUS_realm}#" \
	|perl -npe "s#PrOd_EduRoAm_PhRaSe#${freeRADIUS_cdn_prod_passphrase}#" \
	> /etc/raddb/proxy.conf
	chgrp radiusd /etc/raddb/proxy.conf

# /etc/raddb/clients.conf 
	cat ${templatePath}/etc/raddb/clients.conf.template \
	|perl -npe "s#PrOd_EduRoAm_PhRaSe#${freeRADIUS_cdn_prod_passphrase}#" \
	|perl -npe "s#CLCFG_YaP1_iP#${freeRADIUS_clcfg_ap1_ip}#" \
	|perl -npe "s#CLCFG_YaP1_sEcReT#${freeRADIUS_clcfg_ap1_secret}#" \
	|perl -npe "s#CLCFG_YaP2_iP#${freeRADIUS_clcfg_ap2_ip}#" \
	|perl -npe "s#CLCFG_YaP2_sEcReT#${freeRADIUS_clcfg_ap2_secret}#" \
 	> /etc/raddb/clients.conf
	chgrp radiusd /etc/raddb/clients.conf

# /etc/raddb/certs/ca.cnf (note that there are a few things in the template too like setting it to 10yrs validity )
	cat ${templatePath}/etc/raddb/certs/ca.cnf.template \
	|perl -npe "s#CRT_Ca_StAtE#${freeRADIUS_ca_state}#" \
	|perl -npe "s#CRT_Ca_LoCaL#${freeRADIUS_ca_local}#" \
	|perl -npe "s#CRT_Ca_OrGnAmE#${freeRADIUS_ca_org_name}#" \
	|perl -npe "s#CRT_Ca_EmAiL#${freeRADIUS_ca_email}#" \
	|perl -npe "s#CRT_Ca_CoMmOnNaMe#${freeRADIUS_ca_commonName}#" \
 	> /etc/raddb/certs/ca.cnf
	
# /etc/raddb/certs/server.cnf (note that there are a few things in the template too like setting it to 10yrs validity )
	cat ${templatePath}/etc/raddb/certs/server.cnf.template \
	|perl -npe "s#CRT_SvR_StAtE#${freeRADIUS_svr_state}#" \
	|perl -npe "s#CRT_SvR_LoCaL#${freeRADIUS_svr_local}#" \
	|perl -npe "s#CRT_SvR_OrGnAmE#${freeRADIUS_svr_org_name}#" \
	|perl -npe "s#CRT_SvR_EmAiL#${freeRADIUS_svr_email}#" \
	|perl -npe "s#CRT_SvR_CoMmOnNaMe#${freeRADIUS_svr_commonName}#" \
 	> /etc/raddb/certs/server.cnf

# /etc/raddb/certs/client.cnf (note that there are a few things in the template too like setting it to 10yrs validity )
	cat ${templatePath}/etc/raddb/certs/client.cnf.template \
	|perl -npe "s#CRT_SvR_StAtE#${freeRADIUS_svr_state}#" \
	|perl -npe "s#CRT_SvR_LoCaL#${freeRADIUS_svr_local}#" \
	|perl -npe "s#CRT_SvR_OrGnAmE#${freeRADIUS_svr_org_name}#" \
	|perl -npe "s#CRT_SvR_EmAiL#${freeRADIUS_svr_email}#" \
	|perl -npe "s#CRT_SvR_CoMmOnNaMe#${freeRADIUS_svr_commonName}#" \
 	> /etc/raddb/certs/client.cnf

	echo "Merging variables completed " >> ${statusFile} 2>&1 

# construct default certificates including a CSR for this host in case a commercial CA is used

#	WARNING, see the /etc/raddb/certs/README to 'clean' out certificate bits when you run
#		this script respect the protections freeRADIUS put in place to not overwrite certs

	if [  -e "/etc/raddb/certs/server.crt" ] 
	then
		echo "bootstrap already run, skipping"
	else
	
		(cd /etc/raddb/certs; ./bootstrap )
	fi

# ensure proper start/stop at run level 3 for the machine are in place for winbind,smb, and of course, radiusd
	ckCmd="/sbin/chkconfig"
	ckArgs="--level 3"
	ckState="on" 
	ckServices="winbind smb radiusd"

	for myService in $ckServices
	do
		${ckCmd} ${ckArgs} ${myService} ${ckState}
	done

# disable SELinux as it interferes with the winbind process.

	echo "updating SELinux to disable it" >> ${statusFile} 2>&1 
	cp ${templatePath}/etc/sysconfig/selinux.template /etc/sysconfig/selinux 

# add radiusd to group wbpriv 
	echo "adding user radiusd to WINBIND/SAMBA privilege group wbpriv" >> ${statusFile} 2>&1 
	usermod -a -G wbpriv radiusd


# tweak winbind to permit proper authentication traffic to proceed
# without this, the NTLM call out for freeRADIUS will not be able to process requests
	chmod ugo+rx /var/run/winbindd
				

# disable iptables on runlevels 3,4,5 for reboot and then disable it right now for good measure

#	echo "Disabling iptables" >> ${statusFile} 2>&1 
#	${ckCmd} --level 3 iptables off
#	${ckCmd} --level 4 iptables off
#	${ckCmd} --level 5 iptables off
#	/sbin/service iptables stop

modifyIPTABLESForEduroam


echo "Start Up processes completed" >> ${statusFile} 2>&1 

	
}



doInstall() {
			
			${whiptailBin} --backtitle "${GUIbacktitle}" --title "Deploy eduroam customizations" --defaultno --yes-button "Yes, proceed" --no-button "No, back to main menu" --yesno --clear -- "Proceed with creating restore point and deploying Canadian Access Federation(CAF) eduroam settings?" ${whipSize} 3>&1 1>&2 2>&3
                	continueFwipe=$?
                	if [ "${continueFwipe}" -eq 0 ]
                	then
				eval ${redhatCmdEduroam}	
				echo ""
				echo "Update Completed" >> ${statusFile} 2>&1 
                        	echo "Beginning overlay , creating Restore Point" >> ${statusFile} 2>&1

				createRestorePoint
				deployEduroamCustomizations

				${whiptailBin} --backtitle "${GUIbacktitle}" --title "eduroam customization completed"  --msgbox "Congratulations! eduroam customizations are now deployed!\n\nNext steps: Join this machine to the AD domain by typing \n\nnet join -U Administrator\n\n After, reboot the machine and it should be ready to answer requests. \n\nDecide on your commercial certificate: Self Signed certificates were generated by default. A CSR is located at /etc/raddb/certs/server.csr to request a commercial one. Remember the RADIUS extensions needed though!\n\nFor further configuration details, please see the documentation on disk or the web \n\n Choose OK to return to main menu." 22 75


			else

				${whiptailBin} --backtitle "${GUIbacktitle}" --title "eduroam customization aborted" --msgbox "eduroam customizations WERE NOT done. Choose OK to return to main menu" ${whipSize} 

                	fi
			
			displayMainMenu

}

displayMainMenu() {

                if [ "${GUIen}" = "y" ]
                then
 		#	${whiptailBin} --backtitle "${GUIbacktitle}" --title "Review and Confirm Install Settings" --scrolltext --clear --defaultno --yesno --textbox ${freeradiusfile} 20 75 3>&1 1>&2 2>&3
                  #eduroamTask=$(${whiptailBin} --backtitle "${GUIbacktitle}" --title "Identity Server Main Menu" --cancel-button "exit, no changes" menu --clear  -- "${getStatusString}\nWhich do you want to do?" ${whipSize} 2 review "install Settings" refresh "relevant CentOS packages" install "full eduroam base server" 20 75 3>&1 1>&2 2>&3)

                  eduroamTask=$(${whiptailBin} --backtitle "${GUIbacktitle}" --title "Identity Server Main Menu" --cancel-button "exit" --menu --clear  -- "Which do you want to do?" ${whipSize} 5 refresh "Refresh relevant CentOS packages" review "Review install Settings" installEduroam "Install only the eduroam service" installFedSSO "Install only Federated SSO service"  installAll "Install eduroam and Federated SSO services" 3>&1 1>&2 2>&3)


                else
                        echo "eduroam tasks[ install| uninstall ]"
                        read eduroamTask 
                        echo ""
                fi

		if [ "${eduroamTask}" = "review" ]
		then
			echo "review selected!"
			review
		elif [ "${eduroamTask}" = "refresh" ]
		then	

                        echo "refresh chosen, creating Restore Point" >> ${statusFile} 2>&1
			createRestorePoint
			refresh

		elif [ "${eduroamTask}" = "installEduroam" ]
		then

		if echo "${installer_section0_buildComponentList}" | grep -q "eduroam"; then


	                        echo "install chosen, creating Restore Point" >> ${statusFile} 2>&1
				createRestorePoint
	                        echo "Restore Point Completed" >> ${statusFile} 2>&1
				invokeEduroamInstallProcess
	                        echo "Update Completed" >> ${statusFile} 2>&1

				doInstall
		else
				echo "Sorry, necessary configuration for eduroam is incomplete, please redo config file"
				exit

		fi


		elif [ "${eduroamTask}" = "installFedSSO" ]
		then


			if echo "${installer_section0_buildComponentList}" | grep -q "shibboleth"; then


		                        echo "install of Federated SSO chosen, creating Restore Point" >> ${statusFile} 2>&1
					
					# FIXME: REDUNDANT? --> softwareInstallMaven
					
					invokeShibbolethInstallProcess

					createRestorePoint
		                        echo "Restore Point Completed" >> ${statusFile} 2>&1
				#	eval ${redhatCmdFedSSO}
		                        echo "Update Completed" >> ${statusFile} 2>&1
		    
			else
				echo "Sorry, necessary configuration for shibboleth is incomplete, please redo config file"
				exit
		fi

		elif [ "${eduroamTask}" = "installAll" ]
		then
					

                        echo "install everything chosen, creating Restore Point" >> ${statusFile} 2>&1
			createRestorePoint
                        echo "Restore Point Completed" >> ${statusFile} 2>&1
                        echo "Installing FreeRADIUS and eduroam configuration" >> ${statusFile} 2>&1
			invokeEduroamInstallProcess

			             echo "Installing Shibboleth and Federated SSO configuration" >> ${statusFile} 2>&1
			
			invokeShibbolethInstallProcess

                                echo ""
                                echo "Update Completed" >> ${statusFile} 2>&1

#			doInstall
			
		fi

}
createRestorePoint() {
	# Creates a restore point. Note the tar command starts from / and uses . prefixed paths.
	# this should permit easier, less error prone untar of the file on same machine if needed
	
	rpLabel="RestorePoint-`date +%F-%s`"
	rpFile="${backupPath}/Identity-Appliance-${rpLabel}.tar"

	# record our list of backups
	echo "${rpLabel} ${rpFile}" >> ${backupList}
	bkpCmd="(cd /;tar cfv ${rpFile} ./etc/krb5.conf ./etc/samba ./etc/raddb) >> ${statusFile} 2>&1"
	
	eval ${bkpCmd}

}


validateConfig() {
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

cat > ${freeradiusfile}<< EOM
${settingsHumanReadable}
EOM

}

invokeEduroamInstallProcess ()

{

eval ${redhatCmdEduroam}

}