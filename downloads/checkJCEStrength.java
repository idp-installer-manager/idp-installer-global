import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.security.Security;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
/*
 * A simple test of the JCE crypto strength. 
 *
 * usage: java checkJCEStrength
 *
 * output: 	128 (for the non-export strength/crippled crypto
 *		2147483647 for the prefered unlimited crypto strength 		
 * 
 * July 6, 2015
 * author: Chris Phillips - chris.phillips@canarie.ca
 *
 * inspired by: http://stackoverflow.com/questions/11538746/check-for-jce-unlimited-strength-jurisdiction-policy-files
 *
 */

class checkJCEStrength {
    public static void main(String[] args) {
try {
	int maxKeyLen = Cipher.getMaxAllowedKeyLength("AES");
    	System.out.println(maxKeyLen);
    }catch (Exception e)
    {	e.toString();
    }


}
}

