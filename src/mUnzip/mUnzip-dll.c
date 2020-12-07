// mUnzip DLL

// inclusions
#include <windows.h>

#include "..\..\structs.h"
#include "..\..\decs.h"


// macros
#define VERSION			"1.0"

#define MIRCDECL		int __stdcall
#define MIRCPARAMS	HWND mWnd, HWND aWnd, char *data, char *parms, BOOL show, BOOL nopause

#define WM_MCOMMAND	WM_USER + 200

#define RetErr(Msg, Desc)		{ lstrcpy(data, "E_" Msg " " Desc); return 3; }
#define RetOK				{ lstrcpy(data, "S_OK"); return 3; }

#define case_flag(fcexp, fchar)	\
	case fcexp: \
		mDCL.n ## fchar ## flag = TRUE; \
		break;


// forward references
BOOL mIRCExec(char *Command);
BOOL mIRCSign(char *Message);

int WINAPI fPrint(LPSTR buf, unsigned long size);
int WINAPI fReplace(char *filename);
int WINAPI fPassword(char *p, int n, const char *m, const char *name);
void WINAPI fAppMsg(unsigned long ucsize, unsigned long csiz, unsigned cfactor,
    unsigned mo, unsigned dy, unsigned yr, unsigned hh, unsigned mm, char c, LPSTR filename,
		LPSTR methbuf, unsigned long crc, char fCrypt);
int WINAPI fCallBk(LPCSTR buf, unsigned long size);


// global variables and structures
typedef struct {
	DWORD mVersion;
	HWND mHwnd;
	BOOL mKeep;
} LOADINFO;

char *MapView, Signal[51], Rpl[10];
HWND hWnd;
UINT Commenting;


// standard function replacements
char *Kstrchr(char *string, char chr) {
	while (*string) {
		if (*string == chr) return string;
		string++;
	}
	return NULL;
}


// now, the code

void __stdcall LoadDll(LOADINFO *li) {
	li->mKeep = TRUE;
}

/*
	Use: Unzip -[flags] [signal] [wildmask] <zip filename> <output dir>
	Specify -S to define your own signal suffix, -M to define wildmask
*/
MIRCDECL Unzip(MIRCPARAMS) {
  DCL mDCL;
	USERFUNCTIONS UserFuncs;
	char *p = data, *p2, *infile, *outdir, Flags[30], *Mask;
	HANDLE hFile;
	BOOL HasSignal = FALSE, HasMask = FALSE;
	int RVal;

	hFile = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, 1024, "mIRC");
	if (!hFile) RetErr("NOCOMM", "Can't communicate with mIRC");
	MapView = (char*)MapViewOfFile(hFile, FILE_MAP_ALL_ACCESS, 0, 0, 0);
	if (!MapView) RetErr("NOCOMM", "Can't communicate with mIRC");
	hWnd = mWnd;

	mDCL.ExtractOnlyNewer = FALSE;	// -E
	mDCL.SpaceToUnderscore = FALSE;
	mDCL.PromptToOverwrite = TRUE;
	mDCL.fQuiet = 0;			// -Q<n>
	mDCL.ncflag = FALSE;
	mDCL.ntflag = FALSE;	// -t
	mDCL.nvflag = FALSE;	// -v
	mDCL.nfflag = FALSE;	// -f
	mDCL.nzflag = FALSE;	// -z
	mDCL.ndflag = 0;			// -d = 1
	mDCL.noflag = FALSE;	// -o
	mDCL.naflag = FALSE;	// -a
	mDCL.nZIflag = FALSE; // -Z
	mDCL.C_flag = TRUE;
	mDCL.fPrivilege = 1;	// ???

	ZeroMemory(&UserFuncs, sizeof(UserFuncs));
	UserFuncs.print = fPrint;
	UserFuncs.sound = NULL;
	UserFuncs.replace = fReplace;
	UserFuncs.password = fPassword;
	UserFuncs.SendApplicationMessage = fAppMsg;
	UserFuncs.ServCallBk = fCallBk;

	// read flags...
	if (*p == '-')
		for (p++; *p && *p != ' '; p++)
			switch (*p) {
				case 'E':
					mDCL.ExtractOnlyNewer = TRUE;
					mDCL.PromptToOverwrite = FALSE;
					mDCL.noflag = FALSE;
					break;
				case 'o':
					mDCL.noflag = TRUE;
					mDCL.PromptToOverwrite = FALSE;
					mDCL.ExtractOnlyNewer = FALSE;
					break;
				case 'Q':
					p++;
					if ((*p == '1') || (*p == '2'))
						mDCL.fQuiet = *p - '0';
					else if ((*p == ' ') || !*p)
						RetErr("INVPARM", "Invalid parameters");
					break;
				case 'Z':
					mDCL.nZIflag = TRUE;
					break;
				case 'd':
					mDCL.ndflag = 1;
					break;
				case 'S':
					HasSignal = TRUE;
					break;
				case 'M':
					HasMask = TRUE;
					break;
				// these are macro shortcuts to simpler flags
				case_flag('t', t)
				case_flag('v', v)
				case_flag('f', f)
				case_flag('z', z)
				case_flag('a', a)
			}
	Commenting = mDCL.nzflag? 1 : 0;
	// skip spaces
	while (*p == ' ') p++;
	// no more parameters? bad.
	if (!*p) RetErr("MISSPARM", "Missing parameters");

	// include signal, if specified
	if (HasSignal) {
		p2 = strchr(p, ' ');
		if (!p2) RetErr("INVPARM", "Invalid parameters");
		// let's see if we won't get a buffer overflow...
		if (p2 - p >= sizeof(Signal)) RetErr("INVSIGN", "Signal too long");
		p2 = Signal;
		while (*p != ' ') {
			if ((*p == '*') || (*p == '?')) RetErr("INVSIGN", "Invalid character in signal");
			*p2 = *p;
			p++;
			p2++;
		}
		// skip spaces
		while (*p == ' ') p++;
		// no more parameters? bad.
		if (!*p) RetErr("MISSPARM", "Missing parameters");
	}
	else Signal[0] = '\0';

	// include mask, if specified
	if (HasMask) {
		p2 = strchr(p, ' ');
		if (!p2) RetErr("INVPARM", "Invalid parameters");
		Mask = GlobalAlloc(0, p2 - p + 1);
		if (Mask) {
			*p2 = Mask[0] = '\0';
			lstrcpy(Mask, p);
		}
		p = ++p2;
		// skip spaces
		while (*p == ' ') p++;
		// no more parameters? bad.
		if (!*p) RetErr("MISSPARM", "Missing parameters");
	}
	else
		Mask = NULL;

	// read infile now
	// if the filename is surrounded by quotes...
	if (*p == '"') {
		// ...read until the next quote
		infile = ++p;
		p = Kstrchr(p, '"');
		// the quote wasn't closed? bad.
		if (!p) RetErr("INVPARM", "Invalid parameters");
		*p = '\0';
	}
	else {
		// ...read until next space
		infile = p;
		p = Kstrchr(p, ' ');
		// no space? that means no third parameter, which is bad.
		if (!p) RetErr("INVPARM", "Invalid parameters");
		*p = '\0';
	}
	// go to next character...
	p++;
	// skip spaces
	while (*p == ' ') p++;
	// no more parameters? bad.
	if (!*p) RetErr("MISSPARM", "Missing parameters");

	// finally, read the output directory
	// if the directory is surrounded by quotes...
	if (*p == '"') {
		// ...read until the next quote
		outdir = ++p;
		p = Kstrchr(p, '"');
		// the quote wasn't closed? bad.
		if (!p) RetErr("INVPARM", "Invalid parameters");
		*p = '\0';
	}
	else {
		// ...read until next space
		outdir = p;
		p = Kstrchr(p, ' ');
		// no space? that means the parameter ends here.
		// if it has a space, though, stop it.
		if (p) *p = '\0';
	}

	//mDCL.lpszZipFN = "D:\\Temp\\K2 Collection.zip";
	//mDCL.lpszExtractDir = "D:\\Temp\\K2\\";
	mDCL.lpszZipFN = infile;
	mDCL.lpszExtractDir = outdir;

	RVal = Wiz_SingleEntryUnzip(Mask? 1 : 0, Mask? &Mask : NULL, 0, NULL, &mDCL, &UserFuncs);
	if (Mask) GlobalFree(Mask);

	UnmapViewOfFile(MapView);
	CloseHandle(hFile);

	if (RVal == 80) RVal = 0; // don't consider it an error
	switch (RVal) {
		case 0:
		case 1:
		case 2:
			Flags[0] = '\0';
			if (UserFuncs.cchComment) lstrcat(Flags, "c");
			if (RVal) lstrcat(Flags, "w"); // warnings or errors happened
			if (mDCL.nvflag)
				wsprintf(data, "S_OK |+%s|%u %u %u%%|%lu", Flags,
					UserFuncs.TotalSizeComp, UserFuncs.TotalSize, UserFuncs.CompFactor,
					UserFuncs.NumMembers);
			else
				wsprintf(data, "S_OK |+%s", Flags);
			return 3;

		case 3:
			RetErr("INVFILE", "Invalid file format");

		case 4:
		case 5:
		case 6:
		case 7:
			RetErr("NOMEM", "Not enough memory");

		case 9:
			RetErr("FNF", "File not found");

		case 11:
			RetErr("NOMATCH", "No matches for the specified pattern");

		case 50:
			RetErr("DISKFULL", "Disk is full");

		case 51:
			RetErr("SUDDENEOF", "End of file encountered prematurely");

		case 81:
			RetErr("UNSUPRT", "Unsupported decompression methods or decryption found");

		default:
			wsprintf(data, "E_%i Unknown error %i", RVal, RVal);
			return 3;
	}
}

/*
	DLLInfo
	Returns some information about the DLL
*/
MIRCDECL DLLInfo(MIRCPARAMS) {
	lstrcpy(data, "S_OK mUnzip DLL v" VERSION " © Kamek 2002 -- based on Info-ZIP's source");
	return 3;
}

/*
	Reply <reply>
	Tells the dll to perform some reply
*/
MIRCDECL Reply(MIRCPARAMS) {
	if (lstrlen(data) >= sizeof(Rpl)) RetErr("INVRPL", "Reply is too long");
	lstrcpy(Rpl, data);
	CharLower(Rpl);
	RetOK;
}



void FixPaths(char *Path) {
	char *p = Path;

	while (p = Kstrchr(p, '/')) *p = '\\';
}

BOOL MatchStart(char *Text, char *Start) {
	UINT i;

	for (i = 0; Start[i]; i++)
		if (Text[i] != Start[i]) return FALSE;
	return TRUE;
}



BOOL mIRCExec(char *Command) {
	lstrcpy(MapView, Command);
	return SendMessage(hWnd, WM_MCOMMAND, 1, 0);
}

BOOL mIRCSign(char *Message) {
	char Buffer[900], *p = Buffer;

	if (Signal[0]) 
		wsprintf(Buffer, "/.signal -n mUnzip_%s %s", Signal, Message);
	else
		wsprintf(Buffer, "/.signal -n mUnzip %s", Message);

	while (p = Kstrchr(p, 10)) *p = ' ';
	return mIRCExec(Buffer);
}




int WINAPI fPrint(LPSTR buf, unsigned long size) {
	if (size > 1) {
		char Buffer[900];

		//MessageBox(NULL, Buffer, "Debug", MB_OK);
		if (Commenting == 1) {
			char Buf2[900], *p = Buffer, *lp = Buffer;

			lstrcpy(Buffer, buf);
			while (p = Kstrchr(p, 10)) {
				*p = '\0';
				if (p - lp < sizeof(Buf2)) {
					wsprintf(Buf2, "comment %s", lp);
					mIRCSign(Buf2);
				}
				p++;
				lp = p;
			}
			if (lstrlen(lp)) {
				wsprintf(Buf2, "comment %s", lp);
				mIRCSign(Buf2);
			}
			Commenting = 2;
		}
		else if (Commenting == 2);
		else {
			wsprintf(Buffer, "echo %s", buf);
			if (MatchStart(buf, "Target file exists.") || MatchStart(buf, "  inflating:") ||
					MatchStart(buf, "  testing:") || MatchStart(buf, "   skipping:"))
				FixPaths(Buffer);
			mIRCSign(Buffer);
		}
	}
	return size;
}


int WINAPI fReplace(char *filename) {
	char Buffer[900];

	Rpl[0] = '\0';
	wsprintf(Buffer, "replace %s", filename);
	FixPaths(Buffer);
	mIRCSign(Buffer);
	if (!lstrcmp(Rpl, "yes")) return 102;
	if (!lstrcmp(Rpl, "yes all")) return 103;
	if (!lstrcmp(Rpl, "no all")) return 104;
	return 100; // "no", default
}


int WINAPI fPassword(char *p, int n, const char *m, const char *name) {
	// no password handling for now
	return 1;
}


void WINAPI fAppMsg(unsigned long ucsize, unsigned long csiz, unsigned cfactor,
		unsigned mo, unsigned dy, unsigned yr, unsigned hh, unsigned mm, char c, LPSTR filename,
		LPSTR methbuf, unsigned long crc, char fCrypt) {
	char Buffer[900], FBuf[MAX_PATH], Flags[10];
	UINT Year = yr;

	if (Year < 70) Year += 2000;
	else if (Year < 1000) Year += 1900;
	lstrcpy(FBuf, filename);
	FixPaths(FBuf);
	Flags[0] = '\0';
	if (fCrypt == 'E') lstrcat(Flags, "e");
	wsprintf(Buffer, "list %s|%lu %lu %u%%|%02u/%02u/%u %02u:%02u|%lx %s +%s", FBuf,
		ucsize, csiz, cfactor,  mo, dy, Year, hh, mm, crc, methbuf, Flags);
	mIRCSign(Buffer);
}

int WINAPI fCallBk(LPCSTR filename, unsigned long fsize) {
	char Buffer[900];

	Rpl[0] = '\0';
	wsprintf(Buffer, "extracted %s|%lu", filename, fsize);
	FixPaths(Buffer);
	mIRCSign(Buffer);
	if (!lstrcmp(Rpl, "stop")) return 1;
	return 0;
}