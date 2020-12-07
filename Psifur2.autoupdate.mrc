;****************************************************
;
;        mIRC PsiFur Encryption DLL v2.0.1b
;            PsiFur2 Auto Update script
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
; Progress bar
;*********************
dialog PsiFur2.autoupdate {
  title Updating PsiFur to $+(v,%PsiFur2.newver)
  size -1 -1 175 12
  option dbu
  text "", 1, 0 0 175 12
}

;*********************
; Progress bar init
;*********************
on *:dialog:PsiFur2.autoupdate:init:0: {
  PsiFur2.mdxload
  var %x = $dll($scriptdirdlls\mdx.dll,SetControlMDX,$dname 1 ProgressBar smooth > $scriptdirdlls\ctl_gen.mdx)
}

;*********************
; Progress updater
;*********************
; the download portion is about 25% of the whole update.  The rest is replacing files and DLL's
alias -l PsiFur2.autoupdate.download.update  {
  .did -a PsiFur2.autoupdate 1 $gettok($calc(100 * ($sock($sockname).rcvd - %PsiFur2.downloadoffset) / %PsiFur2.downloadlength),1,46) 0 100
  return 0
}

; File replacement. This is about 75% of the update process.
alias -l PsiFur2.autoupdate.unzip.update  {
  .did -a PsiFur2.autoupdate 1 $gettok($calc(100 * ($sock($sockname).rcvd - %PsiFur2.downloadoffset) / %PsiFur2.downloadlength),1,46) 0 100
  return 0
}

;*********************
; New Version Check
;*********************
alias PsiFur2.checkversion {
  if ( $sock( PsiFur2.updatecheck ) ) { sockclose PsiFur2.updatecheck }
  sockopen PsiFur2.checkversion scripting.catreina.com 80
  if %PsiFur2.DebugWindow {
    PsiFur2.Display 6 Checking PsiFur version against latest release...
  }
}

on *:SOCKOPEN:PsiFur2.checkversion:{
  var %ticks $ticks
  while ( $sock( PsiFur2.checkversion ).status != Active ) { 
    if ($calc($ticks - %ticks) > 10000) {
      sockclose PsiFur2.checkversion
      if %PsiFur2.DebugWindow {
        PsiFur2.Display 4 Socket Error: No Response from http://scripting.catreina.com - Please try again later.
      }
      else {
        echo 4 -at Socket Error: No Response from http://scripting.catreina.com - Please try again later.
      }
      return
    }
  }
  sockwrite -n $sockname GET / HTTP/1.0
  sockwrite -n $sockname Accept: */*
  sockwrite -n $sockname Host: scripting.catreina.com
  sockwrite -n $sockname
}

on *:SOCKREAD:PsiFur2.checkversion:{
  var %tmp
  sockread %tmp

  if (%tmp == $null) { return }

  if ( PsiFur2_VERSION isin %tmp ) {
    ; should return #.#.#
    set %PsiFur2.newver $gettok(%tmp,2,32) 

    if (( %PsiFur2.newver < %PsiFur2.version ) || ( %PsiFur2.newver == %PsiFur2.version )) {
      if %PsiFur2.DebugWindow {
        PsiFur2.Display 6 PsiFur does not need to be updated
      }
      sockclose PsiFur2.checkversion
      return
    }
    else {
      ; the script has found an update.
      set %PsiFur2.getupdate true
    }      
  }

  if ( %PsiFur2.getupdate == true ) {
    if ( PsiFur2_RELEASEDATE isin %tmp ) {
      set %PsiFur2.update.releasedate $gettok(%tmp,2,32) 
    }
    elseif ( PsiFur2_AUTHOR isin %tmp ) {
      set %PsiFur2.update.author $gettok(%tmp,2,32) 
    }
    elseif ( PsiFur2_PATH isin %tmp ) {
      set %PsiFur2.update.path $gettok(%tmp,2,32) 
    }
    elseif ( PsiFur2_FILE isin %tmp ) {
      set %PsiFur2.update.file $gettok(%tmp,2,32) 
    }
    elseif ( END PsiFur2 HEADER isin %tmp ) {
    ;  if (( %PsiFur2.getupdate == true ) && (PsiFur2.hash(autoupdate).get == 1)) {
      if ( %PsiFur2.getupdate == true ) {
        ; if the auto-update switch is on, then auto update
        if ($PsiFur2.hash(autoupdate) == 1) {
          $PsiFur2.update
        }
        ; otherwise, prompt to download and install
        else {
          .timer -om 1 5 { PsiFur2.DownloadAvailableUpdate }
        }
      }
    }
  }
}

alias PsiFur2.DownloadAvailableUpdate {
  if ($input(There is an update available. Download and install?,ydq,Update Psifur?)) {
    if %PsiFur2.DebugWindow {
      PsiFur2.Display 6 PsiFur updating...
    }
    $PsiFur2.update
  }
  else {
    if %PsiFur2.DebugWindow {
      PsiFur2.Display 6 PsiFur NOT updating.  Please visit http://scripting.catreina.com to manually update
    }
  }
}

;*********************
; Start the Update
;*********************
alias PsiFur2.update {

  if %PsiFur2.DebugWindow {
    PsiFur2.Display 6 Downloading PsiFur update (Version %PsiFur2.newver $+ )
  }

  if ($sock(PsiFur2.socket)) {
    if %PsiFur2.DebugWindow {
      PsiFur2.Display 4 PsiFur $+(v,%PsiFur2.newver) currently downloading.
    }
    else {
      echo 4 -st PsiFur $+(v,%PsiFur2.newver) currently downloading.
    }
    return
  }

  ; connect to server
  sockopen PsiFur2.socket scripting.strategybox.com 80
}

;*********************
; DL Socket open
;*********************
on *:sockopen:PsiFur2.socket:{
  if ($sockerr) {
    if %PsiFur2.DebugWindow {
      PsiFur2.Display 4 During download: $sockerr - download aborted
    }
    else {
      echo 4 -as *** During download: $sockerr - download aborted
    }
    return
  }

  if $isfile($+(",$scriptdir,%PsiFur2.update.file,")) { .remove $+(",$scriptdir,%PsiFur2.update.file,") }
  write -c $+(",$scriptdir,%PsiFur2.update.file,")
  unset %PsiFur2.downloadlength %PsiFur2.downloadready

  ; request file
  sockwrite -n $sockname GET $+(/downloads/,%PsiFur2.update.file) HTTP/1.0
  sockwrite -n $sockname Accept: */*
  sockwrite -n $sockname Host: scripting.catreina.com
  sockwrite -n $sockname
}

;*********************
; DL Socket read
;*********************
on *:sockread:PsiFur2.socket:{

  ; if we're not ready to start writing the file (didn't get header info yet)..
  if (%PsiFur2.downloadready != 1) {

    ; begin reading header info
    var %PsiFur2.header
    sockread %PsiFur2.header

    while ($sockbr) {
      ; make sure that the file we are attempting to get is there!
      if (* 404 Object Not Found iswm %PsiFur2.header) { 
        ; file wasnt found.  Set a trigger to NOT contiue .. halt isnt working
        set %PsiFur2.finalizeupdate false
        PsiFur2.displayerror $scriptline PsiFur2.autoupdate.mrc File not found: %PsiFur2.update.file
      }
      
      if (Content-length: * iswm %PsiFur2.header) {

        ; got the length of the file
        %PsiFur2.downloadlength = $gettok(%PsiFur2.header,2,32)
      }
      elseif (* !iswm %PsiFur2.header) {

        ; got the header info, ready..
        %PsiFur2.downloadready = 1

        ; because we've received some bytes from the header.. we need to offset the progress counter a bit.
        %PsiFur2.downloadoffset = $sock($sockname).rcvd

        ; got the file info, open progress bar
        PsiFur2.dlg PsiFur2.autoupdate PsiFur2.autoupdate $scriptline PsiFur2.autoupdate.mrc

        ; ready to download, got content length.. so break out of this header loop
        break
      }
      sockread %PsiFur2.header
    }
  }
  ; begin binary download
  sockread 4096 &d

  while ($sockbr) {

    ; call our progress bar updater 
    .timerPsiFur2.downloadtimer -om 1 $calc(100 / $calc(%PsiFur2.downloadlength - %PsiFur2.downloadoffset)) $PsiFur2.autoupdate.download.update

    ; write the data to the end of the file
    bwrite $+(",$scriptdir,%PsiFur2.update.file,") -1 -1 &d

    ; read the next bit
    sockread 4096 &d
  }
  .timerPsiFur2.downloadtimer off
  %PsiFur2.finalizeupdate = true
}

;*********************
; DL Socket read
;*********************
on *:sockclose:PsiFur2.socket:{

  ; close progress bar
  if ($dialog(PsiFur2.autoupdate)) dialog -x PsiFur2.autoupdate

  ; verify that the file was downloaded
  if ($isfile($+(",$scriptdir,%PsiFur2.update.file,"))) {
    if (%PsiFur2.finalizeupdate == true) {

      ; load the "PsiFur2.update.mrc" file. 
      .load -rs $+(",$scriptdir,PsiFur2.update.mrc,")
      
      ; finally, call the PsiFur2.installupdate alias
      PsiFur2.installupdate %PsiFur2.newver $scriptdir $+ %PsiFur2.update.file
    }
  }
}
