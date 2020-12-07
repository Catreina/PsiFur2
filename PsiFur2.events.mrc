;****************************************************
;
;        mIRC PsiFur Encryption DLL v2.0.1b
;       PsiFur2 "on *:DIALOG" Event Handlers
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

;*****************************************
; Main Dialog Event Handlers
;*****************************************

; Catch and parse all the events for the main dialog
on *:dialog:PsiFur2.main:*:*: { 
  goto $devent
  ; the ACTIVE event is undocumented.  It is called when the window
  ; gains or loses focus (I think).  The other events we trap so 
  ; we dont see tons (literally) of : * /goto: 'mouse' not found (line 34, PsiFur2.events.mrc)
  :MOUSE | :CLOSE | :UCLICK | :DCLICK | :RCLICK | :CLOSE | :ACTIVE | :DROP | :EDIT | h
  :INIT  
    ; get ON or OFF status for checkboxes
    did $iif($PsiFur2.hash(encryptall).get == 1,-c,-u) $dname 6
    did $iif($PsiFur2.hash(randkey).get == 1,-c,-u) $dname 7 
    did $iif($PsiFur2.hash(encpriv).get == 1,-c,-u) $dname 8
    did $iif($PsiFur2.hash(autoupdate).get == 1,-c,-u) $dname 9
    did $iif($PsiFur2.hash(debugwindow).get == 1,-c,-u) $dname 10

    ; Load the Crypt-All key selections
    did -r $dname 15 
    didtok $dname 15 32 Static
    did -c $dname 15 $iif($PsiFur2.hash(cryptallkeys).get == $null,1,$PsiFur2.hash(cryptallkeys).get)

    ; Load the Crypt Key slots
    did -r $dname 13
    didtok $dname 13 32 0 1 2 3 4 5 6 7 8 9 A B C D E F
    
    ; first convert the hashfiles usekey value from base-16 to base-10, and add 1
    ; we add one because the index of mIRC Dialog objects is 1, the index for PsiFur
    ; keyslots is 0
    ; and then we can select the correct line in the combo box
    if ($PsiFur2.hash(usekey).get == $null) {
      did -c $dname 13 1
      $PsiFur2.hash(usekey,0).set
      dll $PsiFur2.dll usekey 0
      ; starting with a null usekey gives us nothing in the hashfile.  Get the key for slot 0
      ; and put it into the hashfile
      $PsiFur2.hash(key0,$dll($PsiFur2.dll,getkey,0)).set
    }
    else {
      dll $PsiFur2.dll usekey $PsiFur2.hash(usekey).get
      did -c $dname 13 $calc($base($PsiFur2.hash(usekey).get,16,10) + 1)
    }

    ; Now get the keystream for the current keyslot. 
    did -r $dname 17
    did -a $dname 17 $PsiFur2.hash($+(key,$PsiFur2.hash(usekey).get)).get | h

  :SCLICK | :MENU | goto $did

    ;***************
    ; Options
    ;***************
    ; unused stuff... ICON image, form itself, labels, menu breaks, etc
    :0 | :3 | :5 | :11 | :12 | :14 | :16 | :17 | :500 | :552 | :554 | :556 | h
    :700 | :752 | :755 | h

    ; OK button - save state - saves anything with a value, and all keystreams, to the hashfile
    :1       
      var %PsiFur2.x = 1 | var %PsiFur2.tempKeyHolder 
      while (%PsiFur2.x <= $did(17).lines) {
        %PsiFur2.tempKeyHolder = $+(%PsiFur2.tempKeyHolder,$chr(32),$did(17,%PsiFur2.x)) | inc %PsiFur2.x
      }

      ; now, if there was absolutely no text in the editbox, then we can delete the keystring
      ; no text means no whitespace characters - ie, tab, line feed, carriage return, space (in that order below)
      if ($len($remove(%PsiFur2.tempKeyHolder, $chr(9), $chr(10), $chr(13), $chr(32))) == 0) {
        dll $PsiFur2.dll delkey 0 | $PsiFur2.hash($+(key,$PsiFur2.hash(usekey).get),).set
      }
      ; Otherwise, update the previously selected keyslot with the contents of the editbox
      ; in both the dll and the hashtable
      else {
        dll $PsiFur2.dll setkey %PsiFur2.tempKeyHolder
        $PsiFur2.hash($+(key,$PsiFur2.hash(usekey).get),%PsiFur2.tempKeyHolder).set
      }

      ; update the hashfile with the new default keyslot
      $PsiFur2.hash(usekey,$did(13).seltext).add
      
      ; We also need to get all the keystreams into the hashfile.
      ; now, iterate through all the keys, and save them to the hashfile as well.
      var %PsiFur2.z = 0
      while (%PsiFur2.z <= 15) {
        $PsiFur2.hash($+(key,$base(%PsiFur2.z,10,16)),$dll($PsiFur2.dll,getkey,$base(%PsiFur2.z,10,16))).set
        inc %PsiFur2.z
      }

      ; save settings
      $PsiFur2.savehashtable
      
      ; exit all dialogs
      if ($dialog(0) > 0) {
        var %PsiFur2.y = $dialog(0)
        while (%PsiFur2.y > 0) {
          if (PsiFur2.* iswm $dialog(%PsiFur2.y)) {
            ; it is one of our dialogs. close it
            dialog -x $dialog(%PsiFur2.y)
          }
          dec %PsiFur2.y
        }
      } | h

    ; Cancel button - trash updates
    :2
      ; free the current hashtable 
      if ($hget(PsiFur2.hashtable)) { hfree PsiFur2.hashtable }

      ; load previous settings
      $PsiFur2.loadhashtable
      
      ; close all dialogs
      if ($dialog(0) > 0) {
        var %PsiFur2.y = $dialog(0)
        while (%PsiFur2.y > 0) {
          if (PsiFur2.* iswm $dialog(%PsiFur2.y)) {
            ; it is one of our dialogs. close it
            dialog -x $dialog(%PsiFur2.y)
          }
          dec %PsiFur2.y
        }
      } | h

    ; Encrypt Everything on Send?
    :6 | $PsiFur2.hash(encryptall,$did($did).state).set | h

    ; Use Random Cypher Keyslot?
    :7 | $PsiFur2.hash(randkey,$did($did).state).set | h

    ; Encrypt Private Messages?
    :8 | $PsiFur2.hash(encpriv,$did($did).state).set | h

    ; Auto-Update?
    :9 | $PsiFur2.hash(autoupdate,$did($did).state).set | h

    ; Show Messages?
    :10 | $PsiFur2.hash(debugwindow,$did($did).state).set | set %PsiFur2.debugwindow $PsiFur2.hash(debugwindow).get | h

    ; Default keyslot changed - update the hashtable, replace editbox contents with new keystring value
    :13
      ; potential bug: editboxes return only the first line with $did($did).text
      ; so we check to see how many lines there are, and apend each to the end of a variable.
      ; potential bug: spaces at end of lines are truncated.  We need to re-add them
      var %PsiFur2.x = 1 | var %PsiFur2.tempKeyHolder 
      while (%PsiFur2.x <= $did(17).lines) {
        %PsiFur2.tempKeyHolder = $+(%PsiFur2.tempKeyHolder,$chr(32),$did(17,%PsiFur2.x)) | inc %PsiFur2.x
      }

      ; now, if there was absolutely no text in the editbox, then we can delete the keystring
      ; no text means no whitespace characters - ie, tab, line feed, carriage return, space (in that order below)
      if ($len($remove(%PsiFur2.tempKeyHolder, $chr(9), $chr(10), $chr(13), $chr(32))) == 0) {
        dll $PsiFur2.dll delkey 0 | $PsiFur2.hash($+(key,$PsiFur2.hash(usekey).get),).set
      }
      ; Otherwise, update the previously selected keyslot with the contents of the editbox
      ; in both the dll and the hashtable
      else {
        dll $PsiFur2.dll setkey %PsiFur2.tempKeyHolder
        $PsiFur2.hash($+(key,$PsiFur2.hash(usekey).get),%PsiFur2.tempKeyHolder).set
      }

      ; update the hashfile with the new default keyslot
      $PsiFur2.hash(usekey,$did($did).seltext).set
      
      ; change the usekey setting in the DLL
      dll $PsiFur2.dll usekey $PsiFur2.hash(usekey).get
           
      ; erase anything in the keystream box and replace with the newly selected keyslot
      did -r $dname 17 | did -a $dname 17 $dll($PsiFur2.dll,getkey,$PsiFur2.hash(usekey).get) | h

    ; Crypt-All Keys to use
    :15 | $PsiFur2.hash(cryptallkeys,$did($did,1).sel).add | h

    ;***************
    ; File Menu
    ;***************
    ; Revert to Default Settings
    ; we provided a default hashfile for this specific purpose.
    ; All we do is free the current hashtable, create a new 
    ; hastable, load the default hashfile, load the hashtable
    ; with the hashfile, then save
    :551 | hfree PsiFur2.hashtable | hmake PsiFur2.hashtable 25 
    var %PsiFur2.tmpHash %PsiFur2.hashfile
    set %PsiFur2.hashfile $+(",$scriptdirPsiFur2.default.hash,") | PsiFur2.loadhashtable
    set %PsiFur2.hashfile %PsiFur2.tmpHash | PsiFur2.savehashtable | h
    
    ; check for updates.
    :553 | PsiFur2.checkversion | h
  
    ; unload... dear god NO!!!
    :555 
      if ($dialog(0) > 0) {
        var %PsiFur2.y = $dialog(0)
        while (%PsiFur2.y > 0) {
          if (PsiFur2.* iswm $dialog(%PsiFur2.y)) {
            ; it is one of our dialogs. close it
            dialog -x $dialog(%PsiFur2.y)
          }
          dec %PsiFur2.y
        }
      }

      PsiFur2.savehashtable
      .unload -rs $+(",$scriptdir,PsiFur2.mrc,")
      h

    ; exit the dialogs - all of them
    :557
      if ($dialog(0) > 0) { var %PsiFur2.y = $dialog(0) | while (%PsiFur2.y > 0) {
        if (PsiFur2.* iswm $dialog(%PsiFur2.y)) { dialog -x $dialog(%PsiFur2.y) } | dec %PsiFur2.y }
      } | h
  
    ;***************
    ; Help Menu
    ;***************
    ; Show Help Contents
    ; *** TODO ***
    ; I need to finish creating the HELP file.  Currently it is a basic README.txt
    :751 | PsiFur2.Help | h
    ; if ($isfile($scriptdir $+ PsiFur2.hlp)) { run PsiFur2.hlp } | h

    ; Open the website
    :753 | .run http://scripting.magicguild.com | h
  
    ; connect to the IRC server... new window preferably...
    ; forcing this script to use mIRC 6.1 or later (I think)
    ; for those of you inspecting this script... the dwarfstar round robin is
    ; irc.dwarfstar.net
    :754 | .server -m irc.magicguild.com | h

    ; show the about dialog
    ; *** TODO ***
    ; I need to create the actual ABOUT dialog.  It is currently EMPTY
    :756  ; PsiFur2.dlg PsiFur2.about PsiFur2.about $scriptline PsiFur2.events,mrc | h
}
