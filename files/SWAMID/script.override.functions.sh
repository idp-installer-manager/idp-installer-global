#!/bin/bash

# announce the override action since this is just a plain include
my_local_override_msg="Overriden by ${my_ctl_federation}"
echo "Overriding functions: configContainerSSLServerKey, installCertificates, configShibbolethFederationValidationKey, performStepsForShibbolethUpgradeIfRequired" >> ${statusFile} 2>&1

configContainerSSLServerKey()

{

        #set up ssl store
        if [ ! -s "${certpath}server.key" ]; then
                ${Echo} "Generating SSL key and certificate request"
                openssl genrsa -out ${certpath}server.key 2048 2>/dev/null
                openssl req -new -key ${certpath}server.key -out ${certREQ} -config ${Spath}/files/openssl.cnf -subj "/CN=${certCN}/O=${certOrg}/C=${certC}"
        fi
        if [ "${selfsigned}" = "n" ]; then
                ${Echo} "Put the certificate from TCS in the file: ${certpath}server.crt" >> ${messages}
                ${Echo} "Run: openssl pkcs12 -export -in ${certpath}server.crt -inkey ${certpath}server.key -out ${httpsP12} -name container -passout pass:${httpspass}" >> ${messages}
        else
                openssl x509 -req -days 365 -in ${certREQ} -signkey ${certpath}server.key -out ${certpath}server.crt
                if [ ! -d "/opt/shibboleth-idp/credentials/" ]; then
                        mkdir /opt/shibboleth-idp/credentials/
                fi
                openssl pkcs12 -export -in ${certpath}server.crt -inkey ${certpath}server.key -out ${httpsP12} -name container -passout pass:${httpspass}
        fi
}

installCertificates () {
	echo -e "${my_local_override_msg}" >> ${statusFile} 2>&1


# change to certificate path whilst doing this part
	cd ${certpath}
	${Echo} "Fetching certificate chain from web"
	if [ "${SWAMIDcertChain}" = "tcs" ]; then
		${fetchCmd} ${certpath}/server.chain ${certificateChain}
	else
		${fetchCmd} ${certpath}/server.chain ${digicertChain}
	fi
        if [ ! -s "${certpath}/server.chain" ]; then
                ${Echo} "Can not get the certificate chain, aborting install."
                cleanBadInstall
        fi

        ${Echo} "Installing certificate chain in java cacert keystore"
	cnt=1
	for i in `cat ${certpath}server.chain | sed -re 's/\ /\*\*\*/g'`; do
		n=`${Echo} ${i} | sed -re 's/\*\*\*/\ /g'`
		${Echo} ${n} >> ${certpath}${cnt}.root
		ltest=`${Echo} ${n} | grep "END CERTIFICATE"`
		if [ ! -z "${ltest}" ]; then
			cnt=`expr ${cnt} + 1`
		fi
	done
	ccnt=1
	while [ ${ccnt} -lt ${cnt} ]; do
		md5finger=`${keytool} -printcert -file ${certpath}${ccnt}.root | grep MD5 | cut -d: -f2- | sed -re 's/\s+//g'`
		test=`${keytool} -list -keystore ${javaCAcerts} -storepass changeit | grep ${md5finger}`
		subject=`openssl x509 -subject -noout -in ${certpath}${ccnt}.root | awk -F= '{print $NF}'`
		if [ -z "${test}" ]; then
			${keytool} -import -noprompt -trustcacerts -alias "${subject}" -file ${certpath}${ccnt}.root -keystore ${javaCAcerts} -storepass changeit >> ${statusFile} 2>&1
		fi
		files="`${Echo} ${files}` ${certpath}${ccnt}.root"
		ccnt=`expr ${ccnt} + 1`
	done

	# Fetch ldap cert
	for loopServer in ${ldapserver}; do
		${Echo} "QUIT" | openssl s_client -connect ${loopServer}:636 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' >> ${certpath}/ldap-server.crt
	done

}

configShibbolethFederationValidationKey () {
			echo -e "${my_local_override_msg}" >> ${statusFile} 2>&1


${fetchCmd} ${idpPath}/credentials/md-signer.crt http://md.swamid.se/md/md-signer.crt
	cFinger=`openssl x509 -noout -fingerprint -sha1 -in ${idpPath}/credentials/md-signer.crt | cut -d\= -f2`
	cCnt=1
	while [ "${cFinger}" != "${mdSignerFinger}" -a "${cCnt}" -le 10 ]; do
		${fetchCmd} ${idpPath}/credentials/md-signer.crt http://md.swamid.se/md/md-signer.crt
		cFinger=`openssl x509 -noout -fingerprint -sha1 -in ${idpPath}/credentials/md-signer.crt | cut -d\= -f2`
		cCnt=`expr ${cCnt} + 1`
	done
	if [ "${cFinger}" != "${mdSignerFinger}" ]; then
		 ${Echo} "Fingerprint error on md-signer.crt!\nGet ther certificate from http://md.swamid.se/md/md-signer.crt and verify it, then place it in the file: ${idpPath}/credentials/md-signer.crt" >> ${messages}
	fi

}


performStepsForShibbolethUpgradeIfRequired ()

{

if [ "${upgrade}" -eq 1 ]; then

${Echo} "Previous installation found, performing upgrade."

        eval ${distCmd1} &> >(tee -a ${statusFile})
        cd /opt
        currentShib=`ls -l /opt/${shibDir} | awk '{print $NF}'`
        currentVer=`${Echo} ${currentShib} | awk -F\- '{print $NF}'`
        if [ "${currentVer}" = "${shibVer}" ]; then
                mv ${currentShib} ${currentShib}.${ts}
        fi

        if [ ! -f "${downloadPath}/${shibDir}-${shibVer}.tar.gz" ]; then
                fetchAndUnzipShibbolethIdP
        fi
        tar xzf ${downloadPath}/${shibDir}-${shibVer}.tar.gz -C /opt
        chmod -R 755 /opt/${shibDir}-${shibVer}

        cp /opt/shibboleth-idp/metadata/idp-metadata.xml /opt/${shibDir}/src/main/webapp/metadata.xml
        tar zcfP ${bupFile} --remove-files /opt/shibboleth-idp

        unlink /opt/${shibDir}
        ln -s /opt/${shibDir}-${shibVer} /opt/${shibDir}

        if [ -d "/opt/cas-client-${casVer}" ]; then
                installCasClientIfEnabled
        fi

        if [ -d "/opt/mysql-connector-java-${mysqlConVer}/" ]; then
                cp /opt/mysql-connector-java-${mysqlConVer}/mysql-connector-java-${mysqlConVer}-bin.jar /opt/${shibDir}/lib/
        fi

        setJavaHome
else
        ${Echo} "This is a fresh Shibboleth Install"


fi


}

