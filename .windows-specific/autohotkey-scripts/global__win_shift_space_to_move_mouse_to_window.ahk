; Map Win+Shift+Space to move mouse to center of active window (may be on other monitor)
; Nice workflow: Win+Shift+s then Win+Shift+Space to move win to other screen then move mouse with it.
#Requires AutoHotkey v2.0
#SingleInstance Force

; #: Window key
; +: Shift key

#Include lib/_win_helpers.ahk

; Disable builtin Windows shortcut Win+Space (used to switch keyboard layout)
#Space::

; FIXME?: When scaling is different on primary screen vs target screen, the positioning is wrong !..
#+Space:: {
    win_selector := "A"
    win_center_pos := GetWinCenterPos(win_selector)
    CoordMode("Mouse", "Screen") ; Required to move mouse by absolute screen position
    SendMode("Event") ; Required to see the cursor move to target, otherwise it's moved instantaneously
    MouseMove(win_center_pos.x, win_center_pos.y)
}
