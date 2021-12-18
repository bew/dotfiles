; Map Win+s to toggle/launch the main "Skype" window and move it under mouse cursor

#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key

#Include lib/_win_helpers.ahk

#s::
  ; NOTE: Targetting the window title is not enough,
  ;       it is shared by a few different Skype windows.
  win_launch := "lync.exe"
  win_selector := "ahk_class CommunicatorMainWindowClass"
  if ToggleWinVisibilityOrLaunch(win_selector, win_launch) {
    MoveWinCenteredOn(win_selector, GetMousePos())
  }
  return
