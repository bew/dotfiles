; Map Win+s to toggle the main "Skype" window and put under cursor

#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key

#Include lib/_win_helpers.ahk ; For RaiseWinToCursorOrLaunch

#s::
  ; NOTE: Targetting the window title is not enough,
  ;       it is shared by a few different Skype windows.
  win_launch := "lync.exe"
  win_selector := "ahk_class CommunicatorMainWindowClass"
  RaiseWinToCursorOrLaunch(win_selector, win_launch)
  return
