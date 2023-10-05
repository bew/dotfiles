; Map Win-m to toggle maximization of current window
#Requires AutoHotkey v2.0
#SingleInstance Force

; #: Window key

#m:: {
    if (WinGetMinMax("A") == 1) {
        WinRestore("A")
    } else {
        WinMaximize("A")
    }
}
