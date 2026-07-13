; Map Win+Ctrl+t to toggle the "Teams" window and move it at the center of the monitor with the mouse cursor
;
; NOTE: The window selector doesn't work well though: if multiple Teams window are opened,
;   like the main window, a poped-out tchat, a poped-out conference, ..
;   There is NOTHING that AutoHotKey can use to ONLY select & open/close the _main_ window.
;   So it'll close one then another window, and then reopen the last closed window..
;   => Not the best behavior...
#Requires AutoHotkey v2.0
#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key
; ^: Ctrl key

#Include lib/_win_helpers.ahk

SetTitleMatchMode "RegEx"

#^t:: {
    win_launch := "Teams.exe"
    ; Window selection by exe is not reliable, because it finds the main window,
    ; the small notifications, or the presenter UI when I'm sharing the screen..
    win_selector := "Microsoft Teams$"
    if ToggleWinVisibilityOrLaunch(win_selector, win_launch) {
        mouse_monitor := GetMonitorIncludingPos(GetMousePos())
        MoveWinCenteredOn(win_selector, mouse_monitor.center_pos)
    }
}
