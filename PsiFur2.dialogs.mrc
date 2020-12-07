;****************************************************
;
;               PsiFur v1.1 for XChat
;                     Bagheera
;
;             PsiFur v2.0b port for mIRC
;                     by Jenni
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
;                The Control Panel
;
;****************************************************

dialog PsiFur2.main {
  title PsiFur $+(v,%PsiFur2.version)
  size -1 -1 376 228
  option pixels
  
  button Save, 1, 205 192 84 34, flat ok
  button Cancel, 2, 290 192 84 34, flat cancel
  icon 3, 2 192 200 34,  psifur v2.jpg, 0, noborder

  box Encryption Toggles, 5, 3 3 200 117
    check Encrypt Everything on Send?, 6, 9 19 188 20, left push
    check Use Random Cypher Keyslot?, 7, 9 44 188 20, left push
    check Encrypt Private Messages?, 8, 9 68 188 20, left push
    check Auto-Update?, 9, 9 92 92 20, left push
    check Show Messages?, 10, 102 92 92 20, left push

  box Keyslot Settings, 11, 3 124 200 66
    text Default Keyslot, 12, 9 142 88 15, center
    combo 13, 99 139 98 75, sort vsbar drop
    text Crypt-All Keys, 14, 9 166 88 15, center
    combo 15, 99 163 98 76, sort vsbar drop

  box Default Key Cipher Text, 16, 205 3 169 187
    edit , 17, 208 18 161 166, multi

  menu File, 500
    item Revert to Defaults, 551, 500
    item break, 552, 500
    item Check for Updates, 553, 500
    item break, 554, 500
    item Unload, 555, 500
    item break, 556, 500
    item Exit, 557, 500

  menu Help, 700
    item Contents, 751, 700
    item break, 752, 700
    item Visit Website, 753, 700
    item IRC Server (new window), 754, 700
    item break, 755, 700
    item About, 756, 700
}

dialog PsiFur2.about {
  
}