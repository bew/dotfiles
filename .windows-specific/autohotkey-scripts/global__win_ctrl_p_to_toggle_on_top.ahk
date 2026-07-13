; Map Ctrl+Win+p to toggle AlwaysOnTop for the active window
#Requires AutoHotkey v2.0
#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; #: Window key
; ^: Ctrl key

^#p:: {
    WinSetAlwaysOnTop(-1, "A")

    ; https://www.autohotkey.com/docs/v2/lib/WinGetStyle.htm
    ex_style := WinGetExStyle("A")
    if (ex_style & 0x8)  ; 0x8 is WS_EX_TOPMOST
        on_top_state_str := "always on top"
    else
        on_top_state_str := "normal"

    ToolTip("Window is " on_top_state_str)
    SetTimer () => ToolTip(), -2000 ; remove after 2s
}
