; Map Win+Ctrl+Space to center the active window on its current monitor

#SingleInstance Force

; #: Window key
; ^: Ctrl key

#Include lib/_win_helpers.ahk

#^Space::
  win_selector := "A"
  mouse_monitor := GetMonitorIncludingPos(GetMousePos())
  MoveWinCenteredOn(win_selector, mouse_monitor.center_pos)
  return
