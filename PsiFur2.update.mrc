;****************************************************
;
;        mIRC PsiFur Encryption DLL v2.0.1b
;      PsiFur2 Auto-Update Stand-Alone Script
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

alias PsiFur2.dll { return $PsiFur2.getdll(PsiFur2.dll,15,PsiFur2.aliases.mrc) }
alias PsiFur2.munzip { return $PsiFur2.getdll(mUnzip.dll,16,PsiFur2.aliases.mrc) }
alias PsiFur2.mdx { return $PsiFur2.getdll(mdx.dll,17,PsiFur2.aliases.mrc) }

;*************************************
; InstallUpdate
;*************************************
;
; We need to make sure the script we are updating
; is unloaded entirely.  We make sure of this statically, 
; as this is not intended for widespread use.  Maybe I will
; implement that in a future "updater" version... I dunno.
;

alias PsiFur2.installupdate {

  if %PsiFur2.DebugWindow {
    PsiFur2.Display 6 Unloading PsiFur for update to $+(v,$1)
  }

  ; make sure our PsiFur2 script is unloaded entirely
  .unload -rs $+(",$scriptdir,PsiFur2.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.autoupdate.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.commands.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.dialogs.mrc,")
  .unload -rs $+(",$scriptdir,PsiFur2.events.mrc,")

  if %PsiFur2.DebugWindow {
    PsiFur2.Display 6 Updating PsiFur to $+(v,$1) ...
  }

  ; now, we need to unzip the downloaded file. Passed as $2
  PsiFur2.unzip $1 $+(",$2-,")
}

;*********************
; Unzip interface
;*********************
alias PsiFur2.unzip {
  ; Unzip everything to a temp directory so that we can copy and unload DLLs correctly.
  var %retval = $dll($PsiFur2.munzip,Unzip,-do $2- $+(",$scriptdir,tmp,"))
  if (S_OK* !iswm  %retval) {
    PsiFur2.displayerror $scriptline PsiFur2.update.mrc Error in autoupdate: %retval
  }
  else {
    
    ; update unzipped.  Unload all dlls used by PsiFur
    PsiFur2.unloaddll PsiFur2.dll
    PsiFur2.unloaddll mUnzip.dll
    PsiFur2.unloaddll mdx.dll

    ; get the total number of files in the update
    var %PsiFur2.x = $findfile($+(",$scriptdirtmp,"),*.*,0,4)
    
    ; iterate through the files, moving each to the working dir
    while ( %PsiFur2.x > 0 ) {
    
      ; Get the path of the file, relative to scriptdir\tmp
      var %PsiFur2.relativeFilePath = $remove($findfile($scriptdirtmp,*.*,%PsiFur2.x),$scriptdirtmp\PsiFur2\)

      ; make sure the file exists first 
      if $isfile($+(",$scriptdirtmp\PsiFur2\,%PsiFur2.relativeFilePath,")) { 

        ; Copy the file from the tmp dir to the working directory, overwriting by default
        ; skip mdx.dll, as it does not unload properly, and we wont be upgrading it anyway
        ; Doing it this way allows us to keep MDX.dll in the zipfile for new users, and still
        ; prevent the error it will cause if we try to overwrite it.
        if ( *mdx.dll !iswm %PsiFur2.relativeFilePath ) {
          .copy -o $+(",$scriptdirtmp\PsiFur2\,%PsiFur2.relativeFilePath,") $+(",$scriptdir,%PsiFur2.relativeFilePath,")
        }

        ; Delete the tempfile
        .remove -b $+(",$scriptdirtmp\PsiFur2\,%PsiFur2.relativeFilePath,")
      }

      ; move to the next file
      dec %PsiFur2.x
    }

    ; now delete the tmp folder and its subfolders
    var %PsiFur2.dirs = $finddir($scriptdirtmp,*.*,0,4)
    while ( %PsiFur2.dirs > 0 ) {
      .rmdir $+(",$finddir($scriptdirtmp,*.*, %PsiFur2.dirs ,4),")
      dec %PsiFur2.dirs
    }
    .rmdir $scriptdirtmp

    ;delete the zipfile we downloaded
    .remove -b $2-
    
    ; Now reload the main script
    if %PsiFur2.DebugWindow {
      PsiFur2.Display 6 PsiFur updated to $+(v,$1). Reloading PsiFur
    }
    
    .load -rs $+(",$scriptdir,PsiFur2.mrc,")

    ; and unload ourself
    .unload -rs $+(",$scriptdir,PsiFur2.update.mrc,")
  }
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
alias PsiFur2.unloaddll {
  dll -u $1-
}

;*********************
; Error display
;*********************
alias PsiFur2.displayerror { 
  if %PsiFur2.DebugWindow {
    PsiFur2.Display 4 PsiFur script halted. $3- (Line $1 in file $2 $+ )
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
