#include <PsiFur2.h>

int atol(char *p) {
	int result = 0, sign = 1;
	if (*p == '-') { sign = -1; p++; }
	while (*p >= '0' && *p <= '9') { result *= 10; result += (*p++ - '0'); }
	return result * sign;
}

int hextointc(char c) {
	if(ishexc(c) == false) 	{
		return -1; // failure, not a hex digit
	}

	c = lcasel(c);

  switch(c) {
	  case '0':
		  return 0; break;
	  case '1':
		  return 1; break;
	  case '2':
		  return 2; break;
	  case '3':
		  return 3; break;
	  case '4':
		  return 4; break;
	  case '5':
		  return 5; break;
	  case '6':
		  return 6; break;
	  case '7':
		  return 7; break;
	  case '8':
		  return 8; break;
	  case '9':
		  return 9; break;
	  case 'a':
		  return 10; break;
	  case 'b':
		  return 11; break;
	  case 'c':
		  return 12; break;
	  case 'd':
		  return 13; break;
	  case 'e':
		  return 14; break;
	  case 'f':
		  return 15; break;
	}
	return -1; // failure ? never would get here
}

bool ishexc(char c) {
	c = lcasel(c);
	switch(c)	{
	  case '0':
	  case '1':
	  case '2':
	  case '3':
	  case '4':
	  case '5':
	  case '6':
	  case '7':
	  case '8':
	  case '9':
	  case 'a':
	  case 'b':
	  case 'c':
	  case 'd':
	  case 'e':
	  case 'f':
		  return true;
		  break;
	}
	return false;
}

void lcase(char* buffer) {
	int len = strlen(buffer);

	for(int i = 0; i < len; i++) {
		buffer[i] = tolower(buffer[i]);
	}
}

void ucase(char* buffer) {
	int len = strlen(buffer);

	for(int i = 0; i < len; i++) {
		buffer[i] = toupper(buffer[i]);
	}
}

int lcasel(int c) {
	return tolower(c);
}

int ucasel(int c) {
	return toupper(c);
}

// Function to encrypt data with the unix crypt() command
char *encryptit(char *data) {
  const char *sc = "./01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  char salt[3];
  srand (time (NULL));
  salt[0] = sc[(rand() & 0x7e) >> 1];
  salt[1] = sc[(rand() & 0x7e) >> 1];
  salt[2] = '\0';
  return (crypt(data,salt));
}
