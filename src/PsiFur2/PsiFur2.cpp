#include <PsiFur2.h>

extern "C" {
  // mIRC required Load and UnLoad functions
  void WINAPI LoadDll(LOADINFO* li) {
    li->mKeep = true;
    // Initialize the pseudo random number generator
    srand (time (0));
	}

	int WINAPI UnloadDll(int timeout)	{
		if (!timeout) { 
      return 1;
    } else {
      return 0;
    }
	}

  // Encrypt an incoming plaintext string
  mIRC(plain2cypher) {
    // make sure that the incoming data is there.
    if (strlen(data) < 1) {
      r_err("INVALID_TEXT_LENGTH",E_INVALID_TEXT_LENGTH);
    }
    // Convert incoming data (pointer) to a string class object
    string input(data);

    // generate a random IV
    iv = make_iv();

    // call plain2cypher with our input and random IV. Returns a string object
    string crypted = psifur(input,iv,keystring.at(currentKey),true);

    // check for failure from "psifur"
    /*
    if (crypted.substr(0,5) != "S_OK ") {
      ret(crypted.c_str());
    }
    */

    // convert key number (int) to hex string (char array)
    char tmp[3];
    itoa(currentKey,tmp,16);
    ucase(tmp);

    // create the full crypted info for mIRC
    string retval;
    retval.append("~");
    retval.append(tmp);
    retval.append(iv);
    retval.append("~");
    retval.append(crypted);

    // return a c-style string to mIRC by converting our string
    ret(retval.c_str());
  }

  // Decrypt an encrypted string
  mIRC(cypher2plain) {
    // convert incoming data to string type
    string input(data);

    // make sure that we have something passed to us
    if (input.size() < 7) { 
      r_err("INVALID_TEXT_LENGTH",E_INVALID_TEXT_LENGTH);
    }
    
    // make sure we have a full crypt header
    if ((input.at(0) != '~') || (input.at(5) != '~')) {
      r_err("INVALID_PSIFUR_HEADER",E_INVALID_PSIFUR_HEADER);
    }

    // make sure that the second character is a keyslot
    if (!ishexc(input.at(1))) {
      r_err("INVALID_KEYSLOT_IN_HEADER",E_INVALID_KEYSLOT_IN_HEADER);
    }

    // save the keyslot specification
    int msg_key = hextointc(input.at(1));

    // get the IV - the 7ad in ~A7ad~
    string known_iv = input.substr(2,3);

    // trim off the ~a7ad~ stuff
    input = input.substr(6);

    // check for key existance
    if (keystring.at(msg_key).length() <= 1) {
      r_err("KEY_MISSING",E_KEY_MISSING);
    }

    // decrypt the incoming data
    string plaintext = psifur(input,known_iv,keystring.at(msg_key),false);

    // return the decrypted text
    ret(plaintext.c_str());
  }

  // Set specified keyslot to new keystring
  mIRC(setkeystring) {
    // make sure new keystring data is 6 characters or more
    if (strlen(data) < 6) {
      r_err("INVALID_KEY_LENGTH",E_INVALID_KEY_LENGTH);
    } else {
      // set current key number to new keystring
      keystring.at(currentKey) = data;

      // convert key number (int) to hex string (char array)
      char tmp[3];
      itoa(currentKey,tmp,16);
      ucase(tmp);

      // return new keystring from hash
      r_keyupdate(tmp,keystring.at(currentKey).c_str());
    }
    r_err("INVALID_KEYUPDATE_SLOT",E_INVALID_KEYUPDATE_SLOT);
  }

    // Sets specified keyslot to null, effectively deleting it.
  mIRC(deletekeystring) {
    // set current key numbers keystring to null
    keystring.at(currentKey) = "";

    // convert key number (int) to hex string (char array)
    char tmp[3];
    itoa(currentKey,tmp,16);
    ucase(tmp);

    // return new keystring from hash
    r_keydeleted(tmp);
  }

  // Return keystring in specified slot
  mIRC(getkeystring) {
    // extract keyslot specification and convert to uppercase
    char buff[2];
    buff[0] = data[0];
    buff[1] = '\0';
    ucase(buff);

    // verify that the keyslot is a valid HEX character
    if (ishexc(buff[0])) {
      // convert hex to integer and save 
      int keynum = hextointc(buff[0]);
      r_keystring(keystring.at(keynum).c_str());
    }
    r_err("INVALID_KEY_SLOT",E_INVALID_KEY_SLOT);
  }

  // Set keyslot to use (between 0 and F (15) HEX)
  mIRC(usekeyslot) {
    // extract keyslot specification
    char buff[2];
    buff[0] = data[0];
    buff[1] = '\0';
    ucase(buff);

    // verify that the keyslot is a valid HEX character
    if (ishexc(buff[0])) {
      // convert hex to integer and save 
      int keynum = hextointc(buff[0]);

      // change currentKey to new key
      currentKey = keynum;

      // Return code specifying we are using new key
      r_usekey(buff);
    }
    r_err("INVALID_KEY_SLOT",E_INVALID_KEY_SLOT);
  }

  // Set whether to use random keys during send
  mIRC(randomkeys) {
    // convert incoming data to string type
    string input(data);

    // Turn on random key selection
    if (input.substr(0,3) == "set") {
      randomkey = 1;
      r_setrandkey("yes");
    } 

    // Turn off random key selection
    if (input.substr(0,5) == "clear") {
      randomkey = 0;
      r_setrandkey("no");
    }

    // Get current random key setting
    if (randomkey == 0) {
      r_randkey("no");
    } else {
      r_randkey("yes");
    }
  }

  // Set cryptall on or off
  mIRC(cryptall) {
    // convert incoming data to string type
    string input(data);

    // Turn on encryption of all outbound
    if (input.substr(0,3) == "set") {
      encryptall = 1;
      r_setcryptall("yes");
    }
    
    // Turn off encryption of all outbound
    if (input.substr(0,5) == "clear") {
      encryptall = 0;
      r_setcryptall("no");
    } 

    // Get current random key setting
    if (encryptall == 0) {
      r_cryptall("no");
    } else {
      r_cryptall("yes");
    }
  }

  // Return the last used IV
  mIRC(known_iv) {
    ret(iv.c_str());
  }

  // Encrypt a string
  mIRC(encryp) {
    ret(encryptit(data));
  }

  // Our DLL Versioning routine
  mIRC(dllinfo) {
    ret(DLLINFO);
  }

  // Our DLL Version - just build numbers
  mIRC(version) {
    ret(VERSION);
  }
}