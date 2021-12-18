; Map Win+t to toggle the "Teams" window and put under cursor.
; NOTE: it doesn't work well though, as if multiple Teams window are opened,
;   like the main window, a poped-out tchat, a poped-out conference, ..
;   There is NOTHING that AutoHotKey can detect to ONLY select & open/close the _main_ window.
;   So it'll close one then the other windows, and then reopen the last closed window..
;   => Not the best behavior...

#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key

#Include lib/_win_helpers.ahk

#t::
  win_launch := "Teams.exe"
  win_selector := "ahk_exe Teams.exe"
  if ToggleWinVisibilityOrLaunch(win_selector, win_launch) {
    MoveWinCenteredOn(win_selector, GetMousePos())
  }
  return
