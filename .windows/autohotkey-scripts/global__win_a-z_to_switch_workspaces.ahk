; Map Win+a & Win+z to switch to prev/next Windows workspace
#Requires AutoHotkey v2.0
#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key
; ^: Ctrl key

; Win+{a,z} -> Win+Ctrl+{Left,Right}
#a::Send "#^{Left}"
#z::Send "#^{Right}"
