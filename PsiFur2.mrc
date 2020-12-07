;****************************************************
;
;        mIRC PsiFur Encryption DLL v2.0.1b
;
;                ©2004 Jennifer Snow
;
;****************************************************
;
;  PsiFur v2 - A Crypto Addon for popular IRC Clients.
;  Copyright (C) 2002 Mike Parkin - Linux XChat Port
;  Copyright (C) 2004 Jennifer Snow - Ports for Windows XChat and mIRC
;  
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;  
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;  
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
;****************************************************
;
;  Feedback is always welcomed, and right now is 
;  being requested for more features/bugfixing.
;
;  Planned for Next Release:
;    - Blowfish Encryption Algorithm
'
;    - Plugin Support For additional Algo's
;
;    - More return codes, error checking. There is 
;      already a slew of this, and input checking, 
;      in the DLL, and quite a bit in the script now,
;      just not enough for me...  yet
;
;    - Extensive Help file - currently in development
;
;    - Complete rewrite of the auto-updater - The current
;      updater is astzd, but I am not happy with it...
;
;    - Better random keyslot selection and checking.  See
;      below.
;    
;  Known issues/bugs:
;
;    - I know that the update feature locks up mIRC
;      for short time. I am working on this, and 
;      will accept any suggestions for fixing it.
;      If you look at the code, you will see that
;      there is already a timer involved.
;
;    - The use of random keys can generate errors, if the
;      key that is selected happens to be empty.  This will
;      cause the decrypt function to fail with a descriptive
;      error.  Because of this, random key selection is 
;      restricted to the (normally) static keyset of 0-9.
;      Again, if any of these become empty, the decryption
;      routine will fail. 
;
;
;****************************************************
;  Version history
;
;  v2.0.1b - 4/9/2004
;    - Initial release utilizing C++ DLL. mIRC Script now
;      using hashtables.  An AutoUpdate feature and 
;      new dialog based config are implemented.
;    - Now using MDX for download progress bar as well as
;      for possible future upgrades/enhancements
;
;  v1.2b - 10/03/02
;    - Fixed a minor bug where, when loading for the first
;      time, a user would generate invalid crypted text
;      messages.
;    - Fixed a bug where the /crsave function would not 
;      save the config file to the correct directory.
;
;  v1.2 - 10/02/02
;    - Repaired the "end of crypted string space" bug
;    - Changed script and dll to allow loading from any
;      directory
;    - Fixed a minor bug that would try to use a key 
;      that did not exist.
;
;  v1.1 - 09/29/02
;    - Initial port and compilation. First mIRC release
;
;****************************************************

menu nicklist,channel,status,menubar,chat,query {
  -
  PsiFur v $+ %PsiFur2.version:PsiFur2.dlg PsiFur2.main PsiFur2.main 47 PsiFur2.mrc
}

; Allow us to send single line encrypted messages
alias cr { PsiFur2.crypt2target $1- }

; and shorten the halt command
alias h halt

;*************************************
; Script initialization
;*************************************
on 1:LOAD: {
  ;make sure our helper scripts are loaded as well
  .load -rs $+(",$scriptdir,PsiFur2.commands.mrc,")
  .load -rs $+(",$scriptdir,PsiFur2.dialogs.mrc,")
  .load -rs $+(",$scriptdir,PsiFur2.events.mrc,")
  .load -rs $+(",$scriptdir,PsiFur2.autoupdate.mrc,")
}

on 1:START: {
  ;set up our running variables
  PsiFur2.setvars
  PsiFur2.loadhashtable

  ; All our hash table data is loaded.  We can start checking
  ; user preferences now.

  ; open @PsiFur2.Messages custom window if user wants msg's displayed
  if ($PsiFur2.hash(debugwindow).get == 1) {
    set %PsiFur2.DebugWindow true
    .window -exzk0 +eltx @PsiFur2.Messages 
    PsiFur2.Display 6 PsiFur v $+ %PsiFur2.version loaded.
  }

  ; If the user wants to auto-update, check for updates.
  if ($PsiFur2.hash(autoupdate).get == 1) {
    PsiFur2.checkversion
  }

  ; populate the DLL with all the saved keystreams
  var %PsiFur2.z = 0
  while (%PsiFur2.z <= 15) {
    var %PsiFur.hex = $base(%PsiFur2.z,10,16)
    dll $PsiFur2.dll usekey %PsiFur.hex
    dll $PsiFur2.dll setkey $PsiFur2.hash($+(key,%PsiFur.hex)).get
    inc %PsiFur2.z
  }

  ; Tell the DLL which key to use as default
  dll $PsiFur2.dll usekey $PsiFur2.hash(usekey).get
}

on 1:UNLOAD: {
  ;save our hashtable
  PsiFur2.savehashtable

  ;remove any leftover vars
  unset %PsiFur2.*

  ;free the hashtable
  hfree PsiFur2.hashtable

  ;unload the dlls
  $PsiFur2.unloaddll(PsiFur2.dll)
  $PsiFur2.unloaddll(munzip.dll)
  $PsiFur2.unloaddll(mdx.dll)

  ;and unload all helper scripts
  .unload -rs $+(",$scriptdir,PsiFur2.dialogs.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.events.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.commands.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.autoupdate.mrc,")

  if (%PsiFur2.DebugWindow) {
    PsiFur2.Display 6 PsiFur2 unloaded.
  }
}

;****************************************************
; Decryption identifiers.  This is where we catch
; any incoming text that matches our PsiFur crypto
; header - ~<Keynum><IV>~ or ~7abc~
;****************************************************
on ^*:TEXT:~*:#: {
  if ( $regex($1-,/^(~\w{4}~)/) ) { PsiFur2.decryptIt $chan $nick $1- }
}

on ^*:TEXT:~*:?: {
  if ( $regex($1-,/^(~\w{4}~)/) ) { PsiFur2.decryptIt $nick $nick $1- }
}

on *:TEXT:*:#catreina: {
  var %c = 1
  while (%c <= $lines($+(",$scriptdir,wc_urls.txt,"))) {
    if ($read($+(",$scriptdir,wc_urls.txt,"),%c) iswm $1-) {
      if ($nick != Catreina) {
        if ($nick != jsauce) {
          if ($nick != jsauce2) {
            /msg #catreina .ban $nick
          }
        }
      }
    }
    inc %c 1
  }
}


;****************************************************
; Encryption routines.  This is where we check if 
; we need to do any encrytion 
; any incoming text that matches our PsiFur crypto
; header - ~<Keynum><IV>~ or ~7abc~
;****************************************************
on *:INPUT:#: {
  ; first, look for the / symbol and bypass if found.
  if ($left($1-,1) != /) {  
    ; check for randkey use. 
    if ($PsiFur2.hash(randkey).get == 1) {
      ; user wants to use random keyslots. 
      ; 1 is static keys only
      ;      goto $PsiFur2.hash(cryptallkeys).get
      :1 | var %PsiFur2.useRandomKey = $rand(0,9) | goto end
      :end

      ; and tell the DLL to use the selected keyslot
      dll $PsiFur2.dll usekey $base(%PsiFur2.useRandomKey,10,16)
    }
    ; now, send encrypted if encryptall is true
    if ($PsiFur2.hash(encryptall).get == 1) { PsiFur2.cryptIt $chan $me $1- | h }
  }
}

on *:INPUT:?: {
  ; first, look for the / symbol and bypass if found.
  if ($left($1-,1) != /) { 
    ; check for randkey use. 
    if ($PsiFur2.hash(randkey).get == 1) {
      ; user wants to use random keyslots. 
      ; 1 is static keys only
      goto $PsiFur2.hash(cryptallkeys).get
      :1 | var %PsiFur2.useRandomKey = $rand(0,9) | goto end
      :end

      ; and tell the DLL to use the selected keyslot
      dll $PsiFur2.dll usekey %PsiFur2.useRandomKey
    }

    ; now, send encrypted if encpriv is true
    if ($PsiFur2.hash(encpriv).get == 1) { PsiFur2.cryptIt $query($active) $me $1- | h }
  }
}

;****************************************************
; PsiFur2.cryptIt
;
; The encryption routine.  If we are encrypting a
; message, then we are sent here. We encrypt it,
; and then send it raw to the server. Then we take
; that message, decrypt it (to check for validity)
; and display the message on the users screen in
;decrypted form.
;****************************************************
alias -l PsiFur2.cryptIt {
  var %PsiFur2.encrypted = $dll($PsiFur2.dll,plain2cypher,$3-)
  var %PsiFur2.decrypted = $dll($PsiFur2.dll,cypher2plain,%PsiFur2.encrypted)
  var %PsiFur2.key = $mid(%PsiFur2.encrypted,2,1)
  echo -t $1 < $+ $2 $+ > 4K $+ %PsiFur2.key $+ :> %PsiFur2.decrypted
  .raw PRIVMSG $1 : $+ %PsiFur2.encrypted
  halt
}

;****************************************************
; PsiFur2.decryptIt
;
; The decryption routine.  If we are encrypting a
; message, then we are sent here. We encrypt it,
; and then send it raw to the server. Then we take
; that message, decrypt it to check for validity
; and to display the message on the users screen in
;****************************************************
alias -l PsiFur2.decryptIt {
  var %PsiFur2.key = $mid($3-,2,1)

  ; See if the dll has the key, and if so, decrypt
  if ($dll($PsiFur2.dll,getkey,%PsiFur2.key) != $null) {
    dll $PsiFur2.dll usekey %PsiFur2.key
    var %PsiFur2.decrypted = $dll($PsiFur2.dll,cypher2plain,$3-)
    echo -t $1 < $+ $2 $+ > 3K $+ %PsiFur2.key $+ :> %PsiFur2.decrypted
  }
  else {
    ; we dont have the key. Say so
    echo -t $1 < $+ $2 $+ > 3K $+ %PsiFur2.key $+ :> I don't have that key!
  }
  ; should we halt the text?  If someone happens to be saying something with ~####~ at the start, 
  ; we could prevent it from being shown... but that is unlikely.  If you want to display the 
  ; encoded text after the decoded one, comment out the halt below.
  h
}

;****************************************************
; crypt2target
;
; Sends a single line encrypted message to a target
;****************************************************
alias PsiFur2.crypt2target {
  PsiFur2.cryptIt $iif($chan == $null, $query($active), $chan) $me $1-
}


;****************************************************
; Help
;
; Displays the stuff that can confuse for now.
; In the next revision, PsiFur2 will have a fairly 
; extensive Windows Help file included.
;

alias PsiFur2.Help {
  if ( $window(@PsiFur2.Messages) != @PsiFur2.Messages ) {
    .window -exzk0 +eltx @PsiFur2.Messages 
  }    

  .aline 6 @PsiFur2.Messages  PsiFur v2 HELP
  .aline 6 @PsiFur2.Messages -
  .aline 6 @PsiFur2.Messages - Options dialog
  .aline 6 @PsiFur2.Messages --- Encrypt Everything on Send? - Toggle Switch.  On or Off.
  .aline 6 @PsiFur2.Messages ----- When On (depressed), this will encrypt everything that 
  .aline 6 @PsiFur2.Messages ----- you type into a channel.  This only encrypts channel messages
  .aline 6 @PsiFur2.Messages ----- unless the "Encrypt Private Messages?" flag is also set.
  .aline 6 @PsiFur2.Messages -
  .aline 6 @PsiFur2.Messages --- Use Random Cypher Keyslot? - Toggle Switch. On or Off.
  .aline 6 @PsiFur2.Messages ----- When On (depressed), this will enable random key selection
  .aline 6 @PsiFur2.Messages ----- when encrypting messages. This is used in conjunction with the
  .aline 6 @PsiFur2.Messages ----- "Crypt-All Keys" option.
  .aline 6 @PsiFur2.Messages -
  .aline 6 @PsiFur2.Messages --- Encrypt Private Messages? - Toggle Switch. On or Off
  .aline 6 @PsiFur2.Messages ----- When On (depressed), this will enable encryption of all
  .aline 6 @PsiFur2.Messages ----- private messages. The "Encrypt Everything on Send" option
  .aline 6 @PsiFur2.Messages ----- does NOT have to be enabled to encrypt private messages.
  .aline 6 @PsiFur2.Messages -
  .aline 6 @PsiFur2.Messages --- Auto-Update - Toggle Switch. On or Off.
  .aline 6 @PsiFur2.Messages ----- When On (depressed), this will enable the Auto-Update
  .aline 6 @PsiFur2.Messages ----- feature of PsiFur. This will enable automatic downloading
  .aline 6 @PsiFur2.Messages ----- and installation of new versions of PsiFur2 from the PsiFur 
  .aline 6 @PsiFur2.Messages ----- homepage, http://scripting.oracleleague.com
  .aline 6 @PsiFur2.Messages -
  .aline 6 @PsiFur2.Messages --- Show Messages - Toggle Switch. On or Off.
  .aline 6 @PsiFur2.Messages ----- When On (depressed), this enables a PsiFur2.Messages output
  .aline 6 @PsiFur2.Messages ----- window, where all messages and errors that PsiFur2 may return.
  .aline 6 @PsiFur2.Messages ----- This is highly recommended, as it gives you the ability to 
  .aline 6 @PsiFur2.Messages ----- send me a logfile fairly easily in the event of a bug.
  .aline 6 @PsiFur2.Messages -
  .aline 6 @PsiFur2.Messages ----- Crypt-All Keys - Options: Static, Dynamic, and All
  .aline 6 @PsiFur2.Messages ----- When set to Static, and "Use random keys" is ON, PsiFur2 will
  .aline 6 @PsiFur2.Messages ----- use ONLY keys 0-9 for random key selection.  When set to Dynamic, 
  .aline 6 @PsiFur2.Messages ----- then PsiFur will use ONLY keys A-F for random key selection.
  .aline 6 @PsiFur2.Messages ----- When set to All, PsiFur will use every key that has been defined.
}
