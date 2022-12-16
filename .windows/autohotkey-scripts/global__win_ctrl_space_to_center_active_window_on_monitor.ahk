; Map Win+Ctrl+Space to center the active window on its current monitor

#SingleInstance Force

; #: Window key
; ^: Ctrl key

#Include lib/_win_helpers.ahk

#^Space::
  win_selector := "A"
  win_monitor := GetMonitorIncludingPos(GetWinCenterPos(win_selector))
  MoveWinCenteredOn(win_selector, win_monitor.center_pos)
  return
