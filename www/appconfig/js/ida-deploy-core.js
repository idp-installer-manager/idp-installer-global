// Copyright 2011, 2012, 2013, 2014
//  Anders Lördal, Högskolan i Gävle and SWAMID
//  Chris Phillips, CANARIE Inc.
//
// This file is part of IDP-Deployer
// 
// IDP-Deployer is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// IDP-Deployer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with IDP-Deployer. If not, see <http://www.gnu.org/licenses/>.
// Set the value below to 1 to enable the logging which will include javascript console and alert popups.
var loggingEnabled = 2;

var generatorVersion = 'v30';
var builddate = new Date();

if (loggingEnabled > 1) {
    console.log('GeneratorVersion' + generatorVersion);
}



function simpleCksum(e) {
    for (var r = 0, i = 0; i < e.length; i++) r = (r << 5) - r + e.charCodeAt(i), r &= r;
    return r
}

function duplicateContactInfo() {
    if ($("#dupeData1").is(':checked')) {
        // duplicate information to fields below

        $("#freeRADIUS_svr_state").val($("#freeRADIUS_ca_state").val());
        $("#freeRADIUS_svr_local").val($("#freeRADIUS_ca_local").val());
        $("#freeRADIUS_svr_org_name").val($("#freeRADIUS_ca_org_name").val());
        $("#freeRADIUS_svr_email").val($("#freeRADIUS_ca_email").val());
    }
    update(); // update to ensure the configuration is constructed properly.


}

var PoundSignError = "Sorry, the # is a reserved character due\nto the template parser.\nPlease remove or choose another special character.";
var errorNotValidHostname = "There were improper characters for the hostname.\nThis is just a hostname with NO http:// or ldap://.\n\nPlease correct before proceeding"
var my_ctl_previousSettings = []; // an associative array of settings as they appear in the config file




function refreshComponentsList() {
    // reconstructs the component list each time the checkbox is changed
    // then calls update
    var tmpFieldVal = ""; // local field value is wiped to reconstruct it.

    var varComponentStringEduroam = "eduroam"
    var varComponentStringShibboleth = "shibboleth"
    var varDelimiter = " ";
    if (loggingEnabled) {
        console.log('refreshComponentsList:Starting pass');
    }

    if ($("#ida_component_eduroam").is(':checked')) {
        // duplicate information to fields below
        tmpFieldVal += varDelimiter + varComponentStringEduroam;
        if (loggingEnabled) {
            console.log('refreshComponentsList:eduroam selected, tmpFieldVal:' + tmpFieldVal);
        }

    }

    if ($("#ida_component_shibboleth").is(':checked')) {
        // duplicate information to fields below
        tmpFieldVal += varDelimiter + varComponentStringShibboleth;
        if (loggingEnabled) {
            console.log('refreshComponentsList:shibboleth selected, tmpFieldVal:' + tmpFieldVal);
        }

    }

    $("#installer_section0_buildComponentList").val(tmpFieldVal);

    if (loggingEnabled) {
        console.log('refreshComponentsList:processing complete, components selected in tmpFieldVal:|' + $("#installer_section0_buildComponentList").val() + '|');
    }

    update(); // update to ensure the configuration is constructed properly.


}



function importPreviousSettings() {
    // To do this, we need to split on the lines, then split on the '=' sign and take the right hand side as the value to store

    try {
        var arrayOfLines = $('#importPreviousConfigArea').val().split(/\n/);
        var confirmMSG = "";
        if (loggingEnabled) {
            console.log('Number of lines:' + arrayOfLines.length);
        }

        for (var i = 0; i < arrayOfLines.length; i++) {


            var myCurrentLine = arrayOfLines[i];

            if (loggingEnabled) {
                console.log('importPreviousSettings():working on line |' + myCurrentLine + '| ');
            }

            // only begin interpretting a non empty line or  or zeroth location is not a comment sign
            if ((myCurrentLine.length > 0) && (myCurrentLine.indexOf('#') != 0)) {

                if (myCurrentLine.indexOf('=') > -1) {

                    //var arrayOfNameValuePairs=arrayOfLines[i].split(/=/);
                    //                    var lhs=arrayOfNameValuePairs[0];           // asscoiative array key

                    //                var rhs=(arrayOfNameValuePairs[1]).trim();  // no trailing whitespace in value

                    if (loggingEnabled) {
                        console.log('importPreviousSettings():detected equals sign on line |' + myCurrentLine + '| ');
                    }

                    var arrayOfNameValuePairs = /^(.*)\=\'(.*)\'$/.exec(myCurrentLine);
                    var lhs = arrayOfNameValuePairs[1]; // asscoiative array key
                    var rhs = arrayOfNameValuePairs[2]; // no trailing whitespace in value

                    if (loggingEnabled) {
                        console.log('importPreviousSettings():LHS:RHS:' + arrayOfNameValuePairs.length + '|' + lhs + '|=|' + rhs + '|');
                    }
                    if (loggingEnabled) {
                        console.log('importPreviousSettings():detected equals sign on line |' + myCurrentLine + '| ');
                    }

                    // trapping double quotes as a blank
                    if (loggingEnabled) {
                        console.log('checking for doublequote in: |' + rhs + '| ');
                    }

                    var testdoublequotes = new RegExp(/^\'\'$/); // SCRUB THE INPUT
                    if (testdoublequotes.test(rhs)) {
                        if (loggingEnabled) {
                            console.log('Detected doublequote and replacing with blank string');
                        }
                        rhs = '';
                    } else {
                        if (loggingEnabled) {
                            console.log('skipping slice |' + rhs + '| ');
                        }
                        //                         rhs= rhs.slice(1,rhs.length-1);
                    }
                    my_ctl_previousSettings[lhs] = rhs;

                    if (loggingEnabled) {
                        confirmMSG += 'Variable:' + lhs + ' is ' + rhs + ' with length:' + rhs.length + ' \n';
                    }

                } else {
                    alert('The line: ' + myCurrentLine + 'at row:' + i + 'is missing an equals sign, please reload the page to start again');
                }
            }
            // skip the blank lines

        }
        if (loggingEnabled) {
            console.log(confirmMSG);
            }

        applyImports(); // now load the imports into their respective fields.

    } catch (e) {
        alert(e);
    }

    return false;

}

var suppressedImportKeys = {
    "installer_section0_version": 0,
    "installer_section0_builddate": 0,
    "installer_section0_fingerprint": 0
};


var requiredFieldKeysEduroam = {

    "my_eduroamDomain": 0,

    "krb5_libdef_default_realm": 0,
    "krb5_realms_def_dom": 0,
    "krb5_domain_realm": 0,
    "smb_workgroup": 0,
    "smb_netbios_name": 0,
    "smb_passwd_svr": 0,
    "smb_realm": 0,

    "installer_section2_title": 0,
    "freeRADIUS_realm": 0,
    "freeRADIUS_cdn_prod_passphrase": 0,

    "freeRADIUS_clcfg_ap1_ip": 0,
    "freeRADIUS_clcfg_ap1_secret": 0,
    "freeRADIUS_clcfg_ap2_ip": 0,
    "freeRADIUS_clcfg_ap2_secret": 0,

    "freeRADIUS_pxycfg_realm": 0,

    "installer_section3_title": 0,
    "freeRADIUS_ca_state": 0,
    "freeRADIUS_ca_local": 0,
    "freeRADIUS_ca_org_name": 0,
    "freeRADIUS_ca_email": 0,
    "freeRADIUS_ca_commonName": 0,

    "installer_section4_title": 0,
    "freeRADIUS_svr_state": 0,
    "freeRADIUS_svr_local": 0,
    "freeRADIUS_svr_org_name": 0,
    "freeRADIUS_svr_email": 0,
    "freeRADIUS_svr_commonName": 0,
};


var requiredFieldKeysShibboleth = {


        "appserv": 0,
      "type": 0,
      "idpurl": 0,
      "ntpserver": 0,
      "ldapserver": 0,
      "ldapbinddn": 0,
      "ldappass": 0,
      "ldapbasedn": 0,
      "subsearch": 0,
      "fticks": 0,
      "eptid": 0,
      "google": 0,
      "googleDom": 0,
      "ninc": 0,
      "casurl": 0,
      "caslogurl": 0,
      "certAcro": 0,
      "certLongC": 0,
      "selfsigned": 0,

    "freeRADIUS_svr_country": 0,
    "freeRADIUS_svr_state": 0,
    "freeRADIUS_svr_local": 0,
    "freeRADIUS_svr_org_name": 0,
    "freeRADIUS_svr_email": 0,
    "freeRADIUS_svr_commonName": 0,




};

//var cNeeded="#FFFF00"
//var cNeeded="#FBE89C"
var cNeeded = "#FFDD20"

var cFilled = "#4CC552"
var cNeutral = "#FFFFFF"


    function setDependantFieldColours(desiredHexColour, arrayOfFields) {


        // document.getElementById('installer_section0_buildDescription').style.backgroundColor='#4CC552'
        if (loggingEnabled) {
            console.log('colourFields:entering');
        }


        for (var key in arrayOfFields) {
            var keyLength = (document.getElementById(key)).value.length;

            if (loggingEnabled) {
                console.log('colourFields:' + key + ' is of length:' + keyLength);
            }

            if (keyLength < 1) {
                document.getElementById(key).style.backgroundColor = desiredHexColour
            } else {
                if (loggingEnabled) {
                    console.log('colourFields:' + key + ' is non empty, no colour change');
                }

            }
            // yellow '#FFFF00'




            if (loggingEnabled) {
                console.log('colourFields:exiting');
            }
        }

    }


    function applyImports() {

        for (var key in my_ctl_previousSettings) {
            keyValue = my_ctl_previousSettings[key];
            if (loggingEnabled) {
                console.log('applyImports():About to set field ' + key + ' to:|' + keyValue + '|');
            }

            if (key in suppressedImportKeys) {
                if (loggingEnabled) {
                    console.log('applyImports():**SUPPRESSED setting field |' + key + '| to:|' + keyValue + '|');
                }

            } else {

                $('#' + key).val(keyValue); // jquery to set the value. 

                $('#' + key).css('backgroundColor', cFilled);

                if (loggingEnabled) {
                    console.log('applyImports():Setting field ' + key + ' to:|' + keyValue + '|');
                }
            }

            if (loggingEnabled) {
                console.log('applyImports():Completed setting field ' + key + ' to jquery-value():|' + $('#' + key).val() + '|');
            }
        }

        applyComponentCheckboxes()
        update(); // refresh the updated section

    }

    function applyComponentCheckboxes()

    {
        // called to ensure checkboxes for the component list are checked

        var varComponentStringEduroam = "eduroam"
        var varComponentStringShibboleth = "shibboleth"

        if (loggingEnabled) {
            console.log('applyComponentCheckboxes:Starting pass');
        }

        if (($("#installer_section0_buildComponentList").val()).indexOf(varComponentStringEduroam) > -1) {
            // set thit to true 
            $("#ida_component_eduroam").prop("checked", true);
            if (loggingEnabled) {
                console.log('applyComponentCheckboxes:Setting eduroam checkbox on');
            }

        }


        if (($("#installer_section0_buildComponentList").val()).indexOf(varComponentStringShibboleth) > -1) {
            // set thit to true 
            $("#ida_component_shibboleth").prop("checked", true);
            if (loggingEnabled) {
                console.log('applyComponentCheckboxes:Setting Shibboleth checkbox on');
            }

        }

        if (loggingEnabled) {
            console.log('applyComponentCheckboxes:processing complete');
        }

    }

    function updateCtx(senderObj)

    {
        if (loggingEnabled) {
            console.log('UpdateCtx():about to set the field to filled in');
        }
        senderObj.style.backgroundColor = cFilled;

        update();
    }


    function update() {

        var numFields = 24;
        var progressIncrement = 1 / numFields * 100;
        var progress = 0;
        var output = "";

        // taking some exclusive variables on this page and plugging them in
        // set the eduroam domain
        if (loggingEnabled) {
            console.log('Update():begin mapping');
        }


// enable tooltip support for all tags
        if (loggingEnabled) {
            console.log('Update():enabling tooltips');
        }

$(document).ready(function() {            $("[rel='tooltip']").tooltip();     });


        //////////////////////////// my_eduroamDomain

        if (loggingEnabled) {
            console.log('Update():mapping my_eduroamDomain');
        }
        if (($("#my_eduroamDomain").val()) == undefined) {
            if (loggingEnabled) {
                console.log('my_eduroamDomain is undefined');
            }

        } else {

            if (loggingEnabled) {
                console.log('Update():presets: my_eduroamDomain is:' + $("#my_eduroamDomain").val());
            }

            $("#freeRADIUS_realm").val($("#my_eduroamDomain").val());
            $("#freeRADIUS_pxycfg_realm").val($("#krb5_libdef_default_realm").val());
            $("#smb_realm").val($("#krb5_libdef_default_realm").val());


        };

        //////////////////////////// krb5_libdef_default_realm (lowercasing)

        if (loggingEnabled) {
            console.log('Update():mapping krb5_libdef_default_realm to krb5_realms_def_dom lowercased');
        }
        if (($("#krb5_libdef_default_realm").val()) == undefined) {
            if (loggingEnabled) {
                console.log('krb5_libdef_default_realm is undefined');
            }

        } else {

            if (loggingEnabled) {
                console.log('Update():presets: krb5_libdef_default_realm is:|' + $("#krb5_libdef_default_realm").val() + '|');
            }

            $("#krb5_realms_def_dom").val(($("#krb5_libdef_default_realm").val()).toLowerCase());

            if (loggingEnabled) {
                console.log('Update():presets: krb5_realms_def_dom is:|' + $("#krb5_realms_def_dom").val() + '|');
            }

        };

        //////////////////////////// idpurl

        if (loggingEnabled) {
            console.log('Update():mapping idpurl');
        }

        //      if( ($("#idpurl").val())==undefined )
        if ($("#idpurl").val()) {

            if (loggingEnabled) {
                console.log('Update():presets: idpurl is:|' + $("#idpurl").val() + '|');
            }

            $("#freeRADIUS_svr_commonName").val($("#idpurl").val());

            try {

                var idpurlArray = /^https:\/\/(.*)$/.exec($("#idpurl").val());

                $("#freeRADIUS_svr_commonName").val(idpurlArray[1]); // blunt, and expects the https in place    

            } catch (err) {
                if (loggingEnabled) {
                    console.log('Update():fallback, presets: freeRADIUS_svr_commonName being calculated');
                }

                $("#freeRADIUS_svr_commonName").val($("#idpurl").val()); // ok, failed the https trap 
                if (loggingEnabled) {
                    console.log('Update():presets: freeRADIUS_svr_commonName is:|' + $("#freeRADIUS_svr_commonName").val() + '|');
                }

            }


        }


	if ( ($("#type").val())!=="cas" ) {
		$("#casurlRow").hide();
	} else {
		$("#casurlRow").show();
	}
	if ( ($("#google").val())!=="y" ) {
		$("#googleRow").hide();
	} else {
		$("#googleRow").show();
	}
	if ($("#freeRADIUS_svr_org_name").val() && ! $("#certAcro").val()) {
		var words = $('#freeRADIUS_svr_org_name').val().split(' ');
		var data = ''; 
		$.each(words, function() {
			data += this.substring(0,1);
		});
		$("#certAcro").val(data);
		$("#certAcro").css({'backgroundColor': cFilled});
	}
	if ($("#casurl").val() && ! $("#caslogurl").val()) {
		$("#caslogurl").val($("#casurl").val()+"/login");
		$("#caslogurl").css({'backgroundColor': cFilled});
	}
          if (loggingEnabled) {console.log ('Update():presets:finished preset section'); }

output += "installer_section0_version=\'"+generatorVersion+"\'\n";
output += "installer_section0_builddate=\'"+builddate+"\'\n";
output += "installer_section0_buildDescription=\'"+ $("#installer_section0_buildDescription").val()+ "\'\n";
output += "installer_section0_buildComponentList=\'"+ $("#installer_section0_buildComponentList").val()+ "\'\n";

output += "installer_section0_title=\'Federation Settings\'\n";
output += "my_ctl_federation=\'"+ $("#my_ctl_federation").val()+ "\'\n";
output += "installer_section1_title=\'Active Directory\'\n"; 
output += "krb5_libdef_default_realm=\'"+ $("#krb5_libdef_default_realm").val()+ "\'\n";
output += "krb5_realms_def_dom=\'"+ $("#krb5_realms_def_dom").val()+ "\'\n";
output += "krb5_domain_realm=\'"+ $("#krb5_domain_realm").val()+ "\'\n";
output += "smb_workgroup=\'"+ $("#smb_workgroup").val()+ "\'\n";
output += "smb_netbios_name=\'"+ $("#smb_netbios_name").val()+ "\'\n";
output += "smb_passwd_svr=\'"+ $("#smb_passwd_svr").val()+ "\'\n";
output += "smb_realm=\'"+ $("#smb_realm").val()+ "\'\n";
output += "\n";
output += "installer_section2_title=\'FreeRADIUS\'\n";
output += "freeRADIUS_realm=\'"+ $("#freeRADIUS_realm").val()+ "\'\n";
output += "freeRADIUS_cdn_prod_passphrase=\'"+ $("#freeRADIUS_cdn_prod_passphrase").val()+ "\'\n";
output += "\n";
output += "freeRADIUS_clcfg_ap1_ip=\'"+ $("#freeRADIUS_clcfg_ap1_ip").val()+ "\'\n";
output += "freeRADIUS_clcfg_ap1_secret=\'"+ $("#freeRADIUS_clcfg_ap1_secret").val()+ "\'\n";
output += "freeRADIUS_clcfg_ap2_ip=\'"+ $("#freeRADIUS_clcfg_ap2_ip").val()+ "\'\n";
output += "freeRADIUS_clcfg_ap2_secret=\'"+ $("#freeRADIUS_clcfg_ap2_secret").val()+ "\'\n";
output += "\n";
output += "freeRADIUS_pxycfg_realm=\'"+ $("#freeRADIUS_pxycfg_realm").val()+ "\'\n";
output += "\n";
output += "installer_section3_title=\'FreeRADIUS TLS Certificate Authority settings\'\n";
output += "freeRADIUS_ca_state=\'"+ $("#freeRADIUS_ca_state").val()+ "\'\n";
output += "freeRADIUS_ca_local=\'"+ $("#freeRADIUS_ca_local").val()+ "\'\n";
output += "freeRADIUS_ca_org_name=\'"+ $("#freeRADIUS_ca_org_name").val()+ "\'\n";
output += "freeRADIUS_ca_email=\'"+ $("#freeRADIUS_ca_email").val()+ "\'\n";
output += "freeRADIUS_ca_commonName=\'"+ $("#freeRADIUS_ca_commonName").val()+ "\'\n";
output += "\n";
output += "installer_section4_title=\'FreeRADIUS TLS Server certificate settings\'\n";
output += "freeRADIUS_svr_country=\'"+ $("#freeRADIUS_svr_country").val()+ "\'\n";
output += "freeRADIUS_svr_state=\'"+ $("#freeRADIUS_svr_state").val()+ "\'\n";
output += "freeRADIUS_svr_local=\'"+ $("#freeRADIUS_svr_local").val()+ "\'\n";
output += "freeRADIUS_svr_org_name=\'"+ $("#freeRADIUS_svr_org_name").val()+ "\'\n";
output += "freeRADIUS_svr_email=\'"+ $("#freeRADIUS_svr_email").val()+ "\'\n";
output += "freeRADIUS_svr_commonName=\'"+ $("#freeRADIUS_svr_commonName").val()+ "\'\n";

// SAML configuration portions
output += "appserv=\'"+ $("#appserv").val()+ "\'\n";
output += "type=\'"+ $("#type").val()+ "\'\n";
output += "idpurl=\'"+ $("#idpurl").val()+ "\'\n";
output += "ntpserver=\'"+ $("#ntpserver").val()+ "\'\n";
output += "ldapserver=\'"+ $("#ldapserver").val()+ "\'\n";
output += "ldapbinddn=\'"+ $("#ldapbinddn").val()+ "\'\n";
output += "ldappass=\'"+ $("#ldappass").val()+ "\'\n";
output += "ldapbasedn=\'"+ $("#ldapbasedn").val()+ "\'\n";
output += "subsearch=\'"+ $("#subsearch").val()+ "\'\n";
output += "fticks=\'"+ $("#fticks").val()+ "\'\n";
output += "eptid=\'"+ $("#eptid").val()+ "\'\n";
output += "casurl=\'"+ $("#casurl").val()+ "\'\n";
output += "caslogurl=\'"+ $("#caslogurl").val()+ "\'\n";
output += "google=\'"+ $("#google").val()+ "\'\n";
output += "googleDom=\'"+ $("#googleDom").val()+ "\'\n";
output += "ninc=\'"+ $("#ninc").val()+ "\'\n";
output += "certAcro=\'"+ $("#certAcro").val()+ "\'\n";
output += "certLongC=\'"+ $("#certLongC").val()+ "\'\n";
output += "selfsigned=\'"+ $("#selfsigned").val()+ "\'\n";


output += "my_eduroamDomain=\'"+ $("#my_eduroamDomain").val()+ "\'\n";


//output += "pass=\'"+ $("#pass").val()+ "\'\n";
//output += "httpspass=\'"+ $("#httpspass").val()+ "\'\n";


output += "###\n";

var mycksum= simpleCksum(output);
output += "installer_section0_fingerprint=\'"+mycksum+"\'\n";


    
    $("#outputArea").text(output);    
    return true;
}


    function formSubmit() {
        update();
        return false;
    }


    // help window controls

var popupWidth = screen.width / 3;
var popupHeight = screen.height;
var leftPos = screen.width - popupWidth;
// window.open(this.href, "customWindow", "width=" + popupWidth + ", height=1040, top=0, left=" + leftPos);

var popupWinSettings = 'width=' + popupWidth + ',height=' + popupHeight + ',left=' + leftPos + ',top=100,scrollbars=no,resizable=yes,status=no,location=yes,toolbar=no,menubar=no';
