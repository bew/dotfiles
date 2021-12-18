; Map Win+Shift+Space to move mouse to center of active window (may be on other monitor)
; Nice workflow: Win+Shift+s then Win+Shift+Space to move win to other screen then move mouse with it.

#SingleInstance Force

; #: Window key
; +: Shift key

#Include lib/_win_helpers.ahk

#+Space::
  win_selector := "A"
  win_center_pos := GetWinCenterPos(win_selector)
  CoordMode, Mouse, Screen ; Required to move mouse by absolute screen position
  MouseMove, win_center_pos.x, win_center_pos.y
