; mUnzip sample

alias -l unzdll return $+(", $scriptdir, mUnzip.dll")

on *:LOAD:{
  var %echo
  if ($version < 6) { %echo = Please use mIRC 6.0 or greater. }
  elseif (!$isfile($unzdll)) { %echo = This sample will only work if you put mUnzip.dll on its directory. }
  else { %echo = To run the sample, type '/unzsample'. }
  echo $color(info) -eati2 *** %echo
}
on *:UNLOAD:dll -u $unzdll | unset %unzsample.file

alias unzsample {
  if ($version < 6) { echo $color(info) -ati2 *** Please use mIRC 6.0 or greater. | return }
  var %d = unzsample, %file
  if (!$isfile($unzdll)) { echo $color(info) -ati2 *** mUnzip.dll was not found. | return }
  if ($dialog(%d)) { dialog -v %d }
  else {
    if (*.zip iswm $longfn($1-)) && ($isfile($1-)) { %file = $1- }
    else {
      var %dir = $nofile($findfile($mircdir, *.zip, 1))
      if (!%dir) { %dir = $mircdir }
      %file = $sfile(%dir $+ *.zip, Open zip file)
      if (!$isfile(%file)) { return }
    }
    if ($chr(32) isin %file) && ("*" !iswm %file) { %file = $+(", %file, ") }
    %unzsample.file = %file
    dialog -m %d %d
  }
}

dialog -l unzsample {
  title "Extract zip file"
  size -1 -1 107 144
  option dbu
  text "Archive contents:", 1, 3 3 43 7
  list 2, 3 12 101 68, sort size vsbar
  text "Archive comments:", 3, 3 84 46 7
  edit "", 4, 3 93 101 24, read multi autohs vsbar
  text "", 5, 3 120 100 7, nowrap
  button "Extract", 2901, 21 130 40 10, default ok
  button "Close", 2902, 63 130 40 10, cancel
}
on *:DIALOG:unzsample:init:0:{
  var %file = %unzsample.file
  if (!$isfile(%file)) { unzsample_fail | return }
  if (S_OK* !iswm $dll($unzdll, Unzip, -vS sample %file .)) { unzsample_fail }
  if (S_OK* !iswm $dll($unzdll, Unzip, -zS sample %file .)) { unzsample_fail }
}
on *:DIALOG:unzsample:sclick:2901:{
  var %dir = $sdir($mircdir, Select the target folder)
  if (!$isdir(%dir)) { halt }
  if (S_OK* !iswm $dll($unzdll, Unzip, -Sd sample %unzsample.file %dir)) { beep }
  unset %unzsample.file
}
on *:DIALOG:unzsample:sclick:2902:unset %unzsample.file

alias -l unzsample_fail {
  beep
  dialog -x unzsample
  unset %unzsample.file
}

on *:SIGNAL:mUnzip_sample:{
  if (!$dialog(unzsample)) { return }
  if ($1 == list) {
    var %file = $gettok($2-, 1, 124)
    ; if it's not a directory, add it
    if (*\ !iswm %file) { did -a unzsample 2 %file }
  }
  elseif ($1 == comment) { did -a unzsample 4 $iif($did(unzsample, 4), $crlf) $+ $2- }
  elseif ($1 == replace) {
    %unzsample.repfile = $2-
    dll $unzdll Reply $dialog(unzsample_replace, unzsample_replace, -4)
    unset %unzsample.repfile
  }
  elseif ($1 == echo) {
    if ($2-4 == Target file exists.) { tokenize 32 $1 $5- }
    did -o unzsample 5 1 $2-
  }
}


dialog -l unzsample_replace {
  title "File conflict"
  size -1 -1 148 40
  option dbu
  text "The following file already exists. Replace it?", 1, 3 3 105 7
  text %unzsample.repfile, 2, 9 15 130 7, nowrap
  text "", 2900, 0 0 0 0, result
  button "&Yes", 3, 3 27 34 10
  button "&No", 4, 39 27 34 10, cancel
  button "Y&es to all", 5, 75 27 34 10
  button "N&o to all", 6, 111 27 34 10
  button "", 7, 0 0 0 0, hide default ok
}
on *:DIALOG:unzsample_replace:init:0:did -f $dname 4
; a reply for "no" isn't needed
on *:DIALOG:unzsample_replace:sclick:3,5,6:did -o $dname 2900 1 $gettok(yes.~.yes all.no all, $calc($did - 2), 46) | dialog -k $dname
