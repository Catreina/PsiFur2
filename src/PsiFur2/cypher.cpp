#include <PsiFur2.h>

// parseinput
string psifur(const string input, const string t_iv, const string curKeyStream, bool cryptit) {
  // create the (de)encrypting keystream
  string live_key = make_keystream(input,t_iv,curKeyStream);

  // unpack the input to make ready for (de)encryption
  vector<int> rotate;
  for (int x = 0; x < input.size(); x++) {
    rotate.push_back(int(input.at(x)));
  }

  // unpack the live key to make ready for (de)encryption
  vector<int> keystream;
  for (int y = 0; y < live_key.size(); y++) {
    keystream.push_back(int(live_key.at(y)));
  }

  // (de)encrypt the data
  for(int z = 0; z < rotate.size(); z++) {
    if (cryptit == true) {
      rotate.at(z) = ((rotate.at(z) - 32 + keystream.at(z))%95);
    } else {
      rotate.at(z) = ((rotate.at(z) - 32 - keystream.at(z))%95);
    }

    // fix for PERL modulo fuckups.
    if (rotate.at(z) < 0) {
      rotate.at(z) += 95;
    }

    // finalize by adding the 32 we removed to begin with to the total
    rotate.at(z) += 32;
  }

  // re-pack the (de)encrypted string
  string output;
  for(int a = 0; a < rotate.size(); a++) {
    output.insert(output.end(),char(rotate.at(a)));
  }

  // return the (de)encrypted string
  return(output);
}

string make_keystream(string input,string known_iv,string crypt_key) {
  string return_key, first_key, second_key, round_key;

  // initialize the keystream loop counters
  int rounds = (input.size() / 19) + 1;
  int round = 0;

  // enter encryption loop
  while (round < rounds) {
		++round; // increment loop number
    
    // create the prefix 
    int tmp = (int)input.size() * round;
    char x[MAXLEN];
    itoa(tmp,x,10);

    // modify the crypt_key
    crypt_key = x + crypt_key + known_iv;

    // copy the crypt_key into a temporary var
    char *tmp_key;
    tmp_key = (char *)crypt_key.c_str();

    // create the first part of the keystream
		first_key = crypt(crypt_key.c_str(), known_iv.c_str());
		first_key = first_key.substr(3);
		
    // reverse the key for the second pass
    strrev(tmp_key);

    // create the second part of the keystream
    second_key = crypt(tmp_key,known_iv.c_str());
		second_key = second_key.substr(3);

    // un-reverse the key for subsequent rounds
		strrev(tmp_key);

    // create the round_key
    round_key = first_key + second_key;

    // append the round_key to the return_key
		return_key += round_key;
	};

  // return the keystream
  return return_key;
}

string make_iv(void) {
  // create the random IV
  char tmp[5] = ""; 

  wsprintf(tmp,"%03.3x",int(4095.0 * rand()/(RAND_MAX+1.0))); //rand()%4095);

//  string known_iv("7ad");
  string known_iv(tmp);
  return(known_iv);
}

