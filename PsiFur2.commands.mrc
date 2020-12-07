;****************************************************
;
;        mIRC PsiFur Encryption DLL v2.0.1b
;           PsiFur2 Commands and Aliases
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

;*********************
; DLL/MDX Aliases
;*********************
;
; These also have an advantage... the PsiFur2.loaddll function checks
;   that the dll is actually present, and returns an error if it is not.

alias PsiFur2.dll { return $PsiFur2.getdll(PsiFur2.dll,$scriptline,PsiFur2.commands.mrc) }
alias PsiFur2.mdx { return $PsiFur2.getdll(mdx.dll,$scriptline,PsiFur2.commands.mrc) }
alias PsiFur2.ctl { return $PsiFur2.getdll(ctl_gen.mdx,$scriptline,PsiFur2.commands.mrc) }

; enables us to use h instead of halt.
alias h halt

alias PsiFur2.mdxload {
  var %x = $dll($PsiFur2.mdx,SetMircVersion,$version)
  var %x = $dll($PsiFur2.mdx,MarkDialog,$dname)
}

;*********************
; DLL Pathing routine
;*********************
alias -l PsiFur2.getdll {
  if (!$isfile($+($scriptdir,dlls\,$1))) {
    PsiFur2.displayerror $2 $3- File Not Found: $1
  }
  else {
    return $+(",$scriptdir,dlls\,$1,")
  }
}

;*********************
; DLL Release
;*********************
PsiFur2.unloaddll {
  dll -u $1-
}

;*********************
; Variable Setting
;*********************
alias PsiFur2.setvars {
  set %PsiFur2.version $dll($PsiFur2.dll,version,0)  
  set %PsiFur2.hashfile $+(",$scriptdirPsiFur2.hash,")
  set %PsiFur2.default.hash $+(",$scriptdirPsiFur2.default.hash,")
}

;*********************
; Dialog creation
;*********************
alias PsiFur2.dlg {
  if ((!$3) || (!$4)) { PsiFur2.displayerror $1 $2 Invalid dialog parameters! }
  if ($dialog($1) != $2) {
    dialog -drvm $1 $2
  }
  else {
    dialog -v $1
  }      
}

;*********************
; Hashtable commands
;*********************
alias PsiFur2.loadhashtable {
  ;First, check if our hashtable exists, and if not, create it
  if (!$hget(PsiFur2.hashtable)) { hmake PsiFur2.hashtable 25 }

  ; We check for a user defined hashfile. If we dont find one, 
  ; we want to use a default settings file, which is provided
  ; with the distribution
  ; if both files are missing, start empty
  if ($isfile(%PsiFur2.hashfile)) {
    ;the hash file exists, fill the hashtable
    hload PsiFur2.hashtable %PsiFur2.hashfile
  }
  elseif ($isfile(%PsiFur2.default.hash)) {
    ; load the defaults.  The main hashfile is missing
    hload PsiFur2.hashtable %PsiFur2.default.hash
  }
  else {
    ; Default hashfile not found. Main hashfile not found. Load defaults
    dll $PsiFur2.dll usekey 0 | dll $PsiFur2.dll setkey Default key - leave alone for compatibility
    dll $PsiFur2.dll usekey 1 | dll $PsiFur2.dll setkey Second default key
    dll $PsiFur2.dll usekey 2 | dll $PsiFur2.dll setkey Third default key
    dll $PsiFur2.dll usekey 3 | dll $PsiFur2.dll setkey These keys will be common with a default installation
    dll $PsiFur2.dll usekey 4 | dll $PsiFur2.dll setkey When you change these keys, you will have to distribute them
    dll $PsiFur2.dll usekey 5 | dll $PsiFur2.dll setkey Secure key distribution is a separate issue
    dll $PsiFur2.dll usekey 6 | dll $PsiFur2.dll setkey I would recommend using pgp for distribution
    dll $PsiFur2.dll usekey 7 | dll $PsiFur2.dll setkey Shameless plug for irc.dwarfstar.net
    dll $PsiFur2.dll usekey 8 | dll $PsiFur2.dll setkey This is not military grade encryption
    dll $PsiFur2.dll usekey 9 | dll $PsiFur2.dll setkey You'll want to change these to your own keys and distribute them
    
    ; now enable the Message Window
    $PsiFur2.hash(debugwindow,1).set
  }    
}

alias PsiFur2.savehashtable {
  ;save all our hashtable information to our hashfile
  hsave -o PsiFur2.hashtable %PsiFur2.hashfile
}

alias PsiFur2.hash {
  if (($prop == set) || ($prop == add)) {
    ;add a hashtable entry
    var %PsiFur2.varname = $1
    var %PsiFur2.vardata = $2-
    hadd -m PsiFur2.hashtable %PsiFur2.varname %PsiFur2.vardata
  }
  elseif ($prop == get) {
    ;get a hashtable entry
    var %PsiFur2.varname = $1
    return $hget(PsiFur2.hashtable,%PsiFur2.varname)
  }
}

;*********************
; Message display
;*********************
alias PsiFur2.Display {
  ; if the window was shut, reopen it to display messages
  if ( $window(@PsiFur2.Messages) != @PsiFur2.Messages ) {
    .window -exzk0 +eltx @PsiFur2.Messages 
  }    
  .aline $1 @PsiFur2.Messages *** $2- 
}

;*********************
; Error display
;*********************
alias PsiFur2.displayerror { 
  if %PsiFur2.DebugWindow {
    PsiFur2.Display 4 PsiFur script halted. $3- (Line $1 in file $2 $+)
  } 
  else {
    echo 4 -st *** PsiFur script halted. $3- (Line $1 in file $2 $+)
  }

  if ($dialog(PsiFur2.main)) dialog -x PsiFur2.main

  if ($dialog(0) > 0) {
    var %y = $dialog(0)
    while (%y > 0) { 
      dialog -x $dialog(%y) 
      dec %y
    }
  }
  halt
}
