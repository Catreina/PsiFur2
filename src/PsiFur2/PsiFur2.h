#ifndef __PSIFUR2__
#define __PSIFUR2__
#pragma check_stack(off)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include <ctime>
#include <string>
#include <vector>
#include <encrypt.h>
#include <blowfish.h>
#include <method.h>

using namespace std;

/*****************************
        globals
*****************************/
static int encryptall = 0;              // Encrypt all messages on send?
static int randomkey = 0;               // utilize random key each message?
static int currentKey = 0;              // Index of current key
static vector<string> keystring(16);    // array of keystrings
static string iv;                       // our Random IV

/*****************************
        prototypes
*****************************/
/* from functions.cpp */
void lcase(char*);// lower case string
void ucase(char*);// upper case string
int lcasel(int);// lower case letter
int ucasel(int);// upper case letter
bool ishexc(char);// is this character a hexidecimal digit?
int hextointc(char); // convert hex character to integer (0-15)
char *encryptit(char *data); // encrypt a given string dynamically

/* from cypher.cpp */
// encrypts and decrypts input strings - if cryptit is true, encrypts.  Otherwise decrypts
string psifur(const string input,const string t_iv,const string curkeystream,bool cryptit);
string make_keystream(string,string,string); // creates the cypher keystream
string make_iv(void); // create the random IV


/*****************************
        #defines
*****************************/
/* For standard routines */
#define MIRC_RETURN_HALT	 0
#define MIRC_RETURN_CONTINUE 1
#define MIRC_RETURN_PROCESS	 2
#define MIRC_RETURN_DATA	 3

/* PsiFur Return Status Strings */
#define E_INVALID_KEY_SLOT          "Keyslot values must be a valid hex character from 0-F."
#define E_INVALID_KEYUPDATE_SLOT    "Only dynamic keys may be updated. Please use key slots from A-F."
#define E_INVALID_KEY_LENGTH        "PsiFur keys must be at least 6 characters long.  This includes static keys."
#define E_INVALID_TEXT_LENGTH       "A string to encrypt or decrypt was expected.  A null string (\"\") was encountered."
#define E_INVALID_PSIFUR_HEADER     "The string passed to \"cypher2plain\" did not contain a valid PsiFur header."
#define E_INVALID_KEYSLOT_IN_HEADER "The string passed to \"cypher2plain\" contained an invalid keyslot character."
#define E_KEY_MISSING               "The cypher passed uses a keystream I do not currently have!"

/* Custom settings */
#define mIRC(fname) __declspec(dllexport) int __stdcall fname(HWND mWnd,HWND aWnd,char *data,char *parms,bool show,bool nopause)
#define MAXLEN    900
#define DLLNAME   "PsiFur"
#define VERSION   "2.0.1b"
#define DLLINFO   DLLNAME " " VERSION " ©2004 Jennifer Snow (http://scripting.magicguild.com)"

/* For UnloadDLL */
#define MIRC_EXIT_UNLOAD  0
#define MIRC_EXIT_TIMEOUT 1

/*****************************
   LoadDLL LOADINFO struct
*****************************/
typedef struct {
  DWORD mVersion;
  HWND  mHwnd;
  BOOL  mKeep;
} LOADINFO;

/*****************************
          macros
*****************************/
// Return a halt command
#define r_halt() { return MIRC_RETURN_HALT; }

// Return a continue command 
#define r_cont() { return MIRC_RETURN_CONTINUE; }

// Return a command for mIRC to process
#define r_cmd(cmd, args) { wsprintf(data,"%s",cmd); wsprintf(parms,"%s",args); return MIRC_RETURN_PROCESS; }

// return "set" cryptall state
#define r_setcryptall(in1) { wsprintf(data,"Encrypt everything on send set to: %s",in1); return MIRC_RETURN_DATA; }

// return our cryptall state
#define r_cryptall(in1) { wsprintf(data,"Encrypt everything on send? %s",in1); return MIRC_RETURN_DATA; }

// return "set" randomkey state
#define r_setrandkey(in1) { wsprintf(data,"Random key selection set to: %s",in1); return MIRC_RETURN_DATA; }

// return our randomkey state
#define r_randkey(in1) { wsprintf(data,"Random key selection? %s",in1); return MIRC_RETURN_DATA; }

// return which keyslot we are using
#define r_usekey(in1) { wsprintf(data,"PsiFur key set to %s",in1); return MIRC_RETURN_DATA; }

// return updated keystring
#define r_keyupdate(in1,in2) { wsprintf(data,"Slot %s keystring changed to: %s",in1,in2); return MIRC_RETURN_DATA; }

// return keystring deleted message
#define r_keydeleted(in1) { wsprintf(data,"Slot %s keystring deleted",in1); return MIRC_RETURN_DATA; }

// return keystring for current keyslot
#define r_keystring(in1) { wsprintf(data,"%s",in1); return MIRC_RETURN_DATA; }

//Return basic information to mIRC
#define ret(x) { lstrcpy(data,x); return MIRC_RETURN_DATA; }

// Return an error code/description
#define r_err(errname,errdesc) { wsprintf(data,"E_%s - %s",errname,errdesc); return MIRC_RETURN_DATA; }

#endif /* __PSIFUR2__ */