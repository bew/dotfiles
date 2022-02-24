; Map Win+t to toggle the "Teams" window and move it at the center of the monitor with the mouse cursor
;
; NOTE: The window selector doesn't work well though: if multiple Teams window are opened,
;   like the main window, a poped-out tchat, a poped-out conference, ..
;   There is NOTHING that AutoHotKey can use to ONLY select & open/close the _main_ window.
;   So it'll close one then another window, and then reopen the last closed window..
;   => Not the best behavior...

#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key

#Include lib/_win_helpers.ahk

#t::
  win_launch := "Teams.exe"
  win_selector := "ahk_exe Teams.exe"
  if ToggleWinVisibilityOrLaunch(win_selector, win_launch) {
    mouse_monitor := GetMonitorIncludingPos(GetMousePos())
    MoveWinCenteredOn(win_selector, mouse_monitor.center_pos)
  }
  return