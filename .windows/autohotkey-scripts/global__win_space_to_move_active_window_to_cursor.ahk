; Map Win+Space to move the active window and put it under cursor
#Requires AutoHotkey v2.0
#SingleInstance Force

; #: Window key

#Include lib/_win_helpers.ahk

#Space:: {
    ; 'A' as a window selector is the active window
    win_selector := "A"
    MoveWinCenteredOn(win_selector, GetMousePos())
}
