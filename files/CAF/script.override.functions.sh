#!/bin/bash

# announce the override action since this is just a plain include
my_local_override_msg="Overriden by ${my_ctl_federation}"
my_ctl_functionOverrides="configTomcatSSLServerKey installCertificates configShibbolethFederationValidationKey performStepsForShibbolethUpgradeIfRequired askForSaveConfigToLocalDisk patchShibbolethLDAPLoginConfigs"

echo -e "\n\nOverriding functions: ${my_ctl_functionOverrides}\n\n"


#
#	GLOBAL overrides
#
#  Things you want to be available to any BASH function in the script should be overridden here.

		echo -e "Overriding certOrg, CertCN, certC"
		certOrg="${freeRADIUS_svr_org_name}"
		certCN="${freeRADIUS_svr_commonName}"
		certC="CA"
		certLongC="Canada"
		certAcro="${certOrg}${certC}"

# this command takes 4min 45sec to run on a core i7 8gb ram SSD disk. 
# overriding as the other yum commands 
centosCmdU="yum -y update; yum clean all"
#centosCmdU="yum version"
# -y update; yum clean all"


configTomcatSSLServerKey()

{
		echo -e "${my_local_override_msg}"


	#set up ssl store
	if [ ! -s "${certpath}server.key" ]; then
		${Echo} "Generating SSL key and certificate request"
		openssl genrsa -out ${certpath}server.key 2048 2>/dev/null
		openssl req -new -key ${certpath}server.key -out ${certREQ} -config ${Spath}/files/openssl.cnf -subj "/CN=${certCN}/O=${certOrg}/C=${certC}"
	fi
	if [ "${selfsigned}" = "n" ]; then
		${Echo} "Put the certificate from TCS in the file: ${certpath}server.crt" >> ${messages}
		${Echo} "Run: openssl pkcs12 -export -in ${certpath}server.crt -inkey ${certpath}server.key -out ${httpsP12} -name tomcat -passout pass:${httpspass}" >> ${messages}
	else
		openssl x509 -req -days 365 -in ${certREQ} -signkey ${certpath}server.key -out ${certpath}server.crt
		if [ ! -d "/opt/shibboleth-idp/credentials/" ]; then
			mkdir /opt/shibboleth-idp/credentials/
		fi
		openssl pkcs12 -export -in ${certpath}server.crt -inkey ${certpath}server.key -out ${httpsP12} -name tomcat -passout pass:${httpspass}
	fi
}

installCertificates ()

{
			echo -e "${my_local_override_msg} "

			# Notes
			# 1. CAF does not have access to TCS CA's, nor needs them. Elements have been commented out, but kept here for reference.


# change to certificate path whilst doing this part

# cd ${certpath}
# ${Echo} "Fetching TCS CA chain from web"
# 	${fetchCmd} ${certpath}/server.chain ${certificateChain}
# 	if [ ! -s "${certpath}/server.chain" ]; then
# 		${Echo} "Can not get the certificate chain, aborting install."
# 		cleanBadInstall
# 	fi

# 	${Echo} "Installing TCS CA chain in java cacert keystore"
# 	cnt=1
# 	for i in `cat ${certpath}server.chain | sed -re 's/\ /\*\*\*/g'`; do
# 		n=`${Echo} ${i} | sed -re 's/\*\*\*/\ /g'`
# 		${Echo} ${n} >> ${certpath}${cnt}.root
# 		ltest=`${Echo} ${n} | grep "END CERTIFICATE"`
# 		if [ ! -z "${ltest}" ]; then
# 			cnt=`expr ${cnt} + 1`
# 		fi
# 	done
# 	ccnt=1
# 	while [ ${ccnt} -lt ${cnt} ]; do
# 		md5finger=`keytool -printcert -file ${certpath}${ccnt}.root | grep MD5 | cut -d: -f2- | sed -re 's/\s+//g'`
# 		test=`keytool -list -keystore ${javaCAcerts} -storepass changeit | grep ${md5finger}`
# 		subject=`openssl x509 -subject -noout -in ${certpath}${ccnt}.root | awk -F= '{print $NF}'`
# 		if [ -z "${test}" ]; then
# 			keytool -import -noprompt -trustcacerts -alias "${subject}" -file ${certpath}${ccnt}.root -keystore ${javaCAcerts} -storepass changeit >> ${statusFile} 2>&1
# 		fi
# 		files="`${Echo} ${files}` ${certpath}${ccnt}.root"
# 		ccnt=`expr ${ccnt} + 1`
# 	done
	
}

configShibbolethFederationValidationKey ()

{
			echo -e "${my_local_override_msg}"

			# Notes:
			#  1. the file of the certificate of the signer is saved as 'md-signer.crt' which is generic
			#  2. using SHA256 instead of SHA1 for fingerprint verification

			metadataSigningKeyURL="https://caf-shib2ops.ca/CoreServices/caf_metadata_verify.crt"

			# openssl x509 -noout -fingerprint -sha256 -in ./caf_metadata_verify.crt
			# SHA256 Fingerprint=
			mdSignerFingerSHA256="36:CF:D8:09:0A:88:B8:D7:52:64:E7:90:FE:A1:B6:F7:EC:BE:CF:42:C8:81:AA:F6:F4:59:D3:AE:3B:45:93:04"

			mdSignerFinger="${mdSignerFingerSHA256}"


	${fetchCmd} ${idpPath}credentials/md-signer.crt ${metadataSigningKeyURL}
	cFinger=`openssl x509 -noout -fingerprint -sha256 -in ${idpPath}/credentials/md-signer.crt | cut -d\= -f2`
	cCnt=1
	while [ "${cFinger}" != "${mdSignerFinger}" -a "${cCnt}" -le 10 ]; do
		${fetchCmd} ${idpPath}credentials/md-signer.crt ${metadataSigningKeyURL}
		cFinger=`openssl x509 -noout -fingerprint -sha256 -in ${idpPath}/credentials/md-signer.crt | cut -d\= -f2`
		cCnt=`expr ${cCnt} + 1`
	done
	if [ "${cFinger}" != "${mdSignerFinger}" ]; then
		 ${Echo} "Fingerprint error on md-signer.crt!\nGet ther certificate from ${metadataSigningKeyURL} and verify it, then place it in the file: ${idpPath}/credentials/md-signer.crt" >> ${messages}
	fi

}

patchShibbolethConfigs ()
{

echo -e "${my_local_override_msg}"

# patch shibboleth config files
	${Echo} "Patching config files for ${my_ctl_federation}"
	mv /opt/shibboleth-idp/conf/attribute-filter.xml /opt/shibboleth-idp/conf/attribute-filter.xml.dist

	#cp ${Spath}/files/attribute-filter.xml.swamid /opt/shibboleth-idp/conf/attribute-filter.xml

	${Echo} "patchShibbolethConfigs:Overlaying attribute-filter.xml with CAF defaults"

	cp ${Spath}/files/CAF/attribute-filter.xml.template /opt/shibboleth-idp/conf/attribute-filter.xml
	chmod ugo+r /opt/shibboleth-idp/conf/attribute-filter.xml

	patch /opt/shibboleth-idp/conf/handler.xml -i ${Spath}/${prep}/handler.xml.diff >> ${statusFile} 2>&1

	${Echo} "patchShibbolethConfigs:Overlaying relying-filter.xml with CAF trusts"
	patch /opt/shibboleth-idp/conf/relying-party.xml -i ${Spath}/xml/${my_ctl_federation}/relying-party.xml.diff >> ${statusFile} 2>&1

# 	patch /opt/shibboleth-idp/conf/attribute-resolver.xml -i ${Spath}/xml/${my_ctl_federation}/attribute-resolver.xml.diff >> ${statusFile} 2>&1
	cp ${Spath}/xml/${my_ctl_federation}/attribute-resolver.xml /opt/shibboleth-idp/conf/attribute-resolver.xml

	if [ "${google}" != "n" ]; then
		repStr='<!-- PLACEHOLDER DO NOT REMOVE -->'
		sed -i -e "/^${repStr}$/r ${Spath}/xml/google-filter.add" -e "/^${repStr}$/d" /opt/shibboleth-idp/conf/attribute-filter.xml
		cat ${Spath}/xml/google-relay.diff.template | sed -re "s/IdPfQdN/${certCN}/" > ${Spath}/xml/google-relay.diff
		files="`${Echo} ${files}` ${Spath}/xml/google-relay.diff"
		patch /opt/shibboleth-idp/conf/relying-party.xml -i ${Spath}/xml/google-relay.diff >> ${statusFile} 2>&1
		cat ${Spath}/xml/google.xml | sed -re "s/GoOgLeDoMaIn/${googleDom}/" > /opt/shibboleth-idp/metadata/google.xml
	fi

	if [ "${fticks}" != "n" ]; then
		patch /opt/shibboleth-idp/conf/logging.xml -i ${Spath}/xml/CAF/fticks.diff >> ${statusFile} 2>&1
		touch /opt/shibboleth-idp/conf/fticks-key.txt
		chown ${tcatUser} /opt/shibboleth-idp/conf/fticks-key.txt
	fi

	if [ "${eptid}" != "n" ]; then
		epass=`${passGenCmd}`
# 		grant sql access for shibboleth
		esalt=`openssl rand -base64 36 2>/dev/null`
		cat ${Spath}/xml/${my_ctl_federation}/eptid.sql.template | sed -re "s#SqLpAsSwOrD#${epass}#" > ${Spath}/xml/${my_ctl_federation}/eptid.sql
		files="`${Echo} ${files}` ${Spath}/xml/${my_ctl_federation}/eptid.sql"

		${Echo} "Create MySQL database for Shibboleth ePTiD and shibboleth user for database connection."
		mysql -uroot -p"${mysqlPass}" < ${Spath}/xml/${my_ctl_federation}/eptid.sql
		retval=$?
		if [ "${retval}" -ne 0 ]; then
			${Echo} "Failed to create EPTID database, take a look in the file '${Spath}/xml/${my_ctl_federation}/eptid.sql.template' and corect the issue." >> ${messages}
			${Echo} "Password for the database user can be found in: /opt/shibboleth-idp/conf/attribute-resolver.xml" >> ${messages}
		fi
			
		cat ${Spath}/xml/${my_ctl_federation}/eptid-AR.diff.template \
			| sed -re "s#SqLpAsSwOrD#${epass}#;s#Large_Random_Salt_Value#${esalt}#" \
			> ${Spath}/xml/${my_ctl_federation}/eptid-AR.diff
		files="`${Echo} ${files}` ${Spath}/xml/${my_ctl_federation}/eptid-AR.diff"

# following 2 lines were commented out jan 28th, 2014, but no longer

 		patch /opt/shibboleth-idp/conf/attribute-resolver.xml -i ${Spath}/xml/eptid-AR.diff >> ${statusFile} 2>&1
 		patch /opt/shibboleth-idp/conf/attribute-filter.xml -i ${Spath}/xml/eptid-AF.diff >> ${statusFile} 2>&1

		cat ${Spath}/xml/${my_ctl_federation}/eptid.add.attrCon.template \
			| sed -re "s#SqLpAsSwOrD#${epass}#;s#Large_Random_Salt_Value#${esalt}#" \
			> ${Spath}/xml/${my_ctl_federation}/eptid.add.attrCon
		files="`${Echo} ${files}` ${Spath}/xml/${my_ctl_federation}/eptid.add.attrCon"

		repStr='<!-- EPTID RESOLVER PLACEHOLDER -->'
		sed -i -e "/^${repStr}$/r ${Spath}/xml/${my_ctl_federation}/eptid.add.resolver" -e "/^${repStr}$/d" /opt/shibboleth-idp/conf/attribute-resolver.xml

		repStr='<!-- EPTID ATTRIBUTE CONNECTOR PLACEHOLDER -->'
		sed -i -e "/^${repStr}$/r ${Spath}/xml/${my_ctl_federation}/eptid.add.attrCon" -e "/^${repStr}$/d" /opt/shibboleth-idp/conf/attribute-resolver.xml

		repStr='<!-- EPTID PRINCIPAL CONNECTOR PLACEHOLDER -->'
		sed -i -e "/^${repStr}$/r ${Spath}/xml/${my_ctl_federation}/eptid.add.princCon" -e "/^${repStr}$/d" /opt/shibboleth-idp/conf/attribute-resolver.xml

		repStr='<!-- EPTID FILTER PLACEHOLDER -->'
		sed -i -e "/^${repStr}$/r ${Spath}/xml/${my_ctl_federation}/eptid.add.filter" -e "/^${repStr}$/d" /opt/shibboleth-idp/conf/attribute-filter.xml
	fi

echo "applying chown "
chmod o+r /opt/shibboleth-idp/conf/attribute-filter.xml


}








performStepsForShibbolethUpgradeIfRequired ()

{
			echo -e "${my_local_override_msg}"


if [ "${upgrade}" -eq 1 ]; then

${Echo} "Previous installation found, performing upgrade."

	eval ${distCmd1}
	cd /opt
	currentShib=`ls -l /opt/shibboleth-identityprovider | awk '{print $NF}'`
	currentVer=`${Echo} ${currentShib} | awk -F\- '{print $NF}'`
	if [ "${currentVer}" = "${shibVer}" ]; then
		mv ${currentShib} ${currentShib}.${ts}
	fi

	if [ ! -f "${Spath}/files/shibboleth-identityprovider-${shibVer}-bin.zip" ]; then
		fetchShibboleth
	fi
	unzip -q ${Spath}/files/shibboleth-identityprovider-${shibVer}-bin.zip -d /opt
	chmod -R 755 /opt/shibboleth-identityprovider-${shibVer}

	unlink /opt/shibboleth-identityprovider
	ln -s /opt/shibboleth-identityprovider-${shibVer} /opt/shibboleth-identityprovider

	if [ -d "/opt/cas-client-${casVer}" ]; then
		installCasClientIfEnabled
	fi

	if [ -d "/opt/ndn-shib-fticks" ]; then
		if [ -z "`ls /opt/ndn-shib-fticks/target/*.jar`" ]; then
			cd /opt/ndn-shib-fticks
			mvn >> ${statusFile} 2>&1
		fi
		cp /opt/ndn-shib-fticks/target/*.jar /opt/shibboleth-identityprovider/lib
	else
		fticks=$(askYesNo "Send anonymous data" "Do you want to send anonymous usage data to ${my_ctl_federation}?\nThis is recommended")

		if [ "${fticks}" != "n" ]; then
			installFticksIfEnabled
		fi
	fi

	if [ -d "/opt/mysql-connector-java-${mysqlConVer}/" ]; then
		cp /opt/mysql-connector-java-${mysqlConVer}/mysql-connector-java-${mysqlConVer}-bin.jar /opt/shibboleth-identityprovider/lib/
	fi

	cd /opt
	tar zcf ${bupFile} shibboleth-idp

	cp /opt/shibboleth-idp/metadata/idp-metadata.xml /opt/shibboleth-identityprovider/src/main/webapp/metadata.xml

	setJavaHome
	cd /opt/shibboleth-identityprovider
	${Echo} "\n\n\n\nRunning shiboleth installer"
	sh install.sh -Dinstall.config=no -Didp.home.input="/opt/shibboleth-idp" >> ${statusFile} 2>&1
else
	${Echo} "\nThis is a fresh Shibboleth Install"


fi


}


askForSaveConfigToLocalDisk ()
{

echo -e "${my_local_override_msg}"

# Since everything goes through the config process on the webpage, we do not need this anymore

# cAns=$(askYesNo "Save config" "Do you want to save theese config values?\n\nIf you save theese values the current config file will be ovverwritten.\n NOTE: No passwords will be saved.")

# 	if [ "${cAns}" = "y" ]; then
# 		writeConfigFile
# 	fi

# 	if [ "${GUIen}" = "y" ]; then
# 		${whiptailBin} --backtitle "${my_ctl_federation} IDP Deployer" --title "Confirm" --scrolltext --clear --textbox ${downloadPath}/confirm.tx 20 75 3>&1 1>&2 2>&3
# 	else
# 		cat ${downloadPath}/confirm.tx
# 	fi
# 	cAns=$(askYesNo "Confirm" "Do you want to install this IDP with theese options?" "no")

# 	rm ${downloadPath}/confirm.tx
# 	if [ "${cAns}" = "n" ]; then
# 		exit
# 	fi

}


patchShibbolethLDAPLoginConfigs ()

{

echo -e "${my_local_override_msg}"

#FIXME: alter override for federation aware setting rather than just the 'CAF' one


	# 	application server specific
	if [ "${type}" = "ldap" ]; then
		ldapServerStr=""
		for i in `${Echo} ${ldapserver}`; do
			ldapServerStr="`${Echo} ${ldapServerStr}` ldap://${i}"
		done
		ldapServerStr="`${Echo} ${ldapServerStr} | sed -re 's/^\s+//'`"

		cat ${Spath}/${prep}/CAF/login.conf.diff.template \
			| sed -re "s#LdApUrI#${ldapServerStr}#;s/LdApBaSeDn/${ldapbasedn}/;s/SuBsEaRcH/${subsearch}/;s/LdApCrEdS/${ldapbinddn}/;s/LdApPaSsWoRd/${ldappass}/" \
			> ${Spath}/${prep}/CAF/login.conf.diff
		files="`${Echo} ${files}` ${Spath}/${prep}/CAF/login.conf.diff"
		patch /opt/shibboleth-idp/conf/login.config -i ${Spath}/${prep}/CAF/login.conf.diff >> ${statusFile} 2>&1
	fi

}

# s/LdApCrEdS/${ldapbinddn}/;s/LdApPaSsWoRd/${ldappass}/


