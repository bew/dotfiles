; Map Win+Space to move the active window and put it under cursor

#SingleInstance Force

; #: Window key

#Include lib/_win_helpers.ahk ; For MoveWinToCursor

#Space::
  ; 'A' as a window selector is the active window
  MoveWinToCursor("A")
  return
