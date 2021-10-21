; Map Ctrl+Win+p to toggle AlwaysOnTop for the active window

#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key
; ^: Ctrl key

^#p::

WinSet, AlwaysOnTop, Toggle, A

; https://www.autohotkey.com/docs/commands/WinGet.htm#ExStyle
WinGet, ex_style, ExStyle, A
If (ex_style & 0x8)  ; 0x8 is WS_EX_TOPMOST
    on_top_state_str = always on top
Else
    on_top_state_str = normal

ToolTip, Window is %on_top_state_str%
SetTimer, remove_tool_tip, -2000
return

remove_tool_tip:
ToolTip ; Set current tooltip to blank, removing it
return

; Note: 'A' for a WinTitle parameter is the active window
; https://www.autohotkey.com/docs/misc/WinTitle.htm
