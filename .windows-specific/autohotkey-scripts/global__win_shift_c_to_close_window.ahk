; Map Win+Shift+c to close the active window (but not the whole program)
#Requires AutoHotkey v2.0
#SingleInstance Force

; #: Window key
; +: Shift key

; A: the active window
#+c:: {
    ; NOTE: We don't use 'WinClose', because it sends a WM_CLOSE message to the target window,
    ;       which is a somewhat forceful method of closing it.
    ;       => For example on a Skype window, closes all Skype windows :/
    ;
    ; Ref: https://www.autohotkey.com/docs/v2/lib/WinClose.htm#Remarks
    ; Ref: https://www.autohotkey.com/docs/v2/lib/PostMessage.htm
    ; Tuto: https://www.autohotkey.com/docs/v2/misc/SendMessage.htm
    ;
    ; Here is a nicer method to close a window, it's not a program force close, instead it's similar
    ; to pressing Alt+F4 or clicking the window's close button in its title bar.
    PostMessage 0x0112, 0xF060,,, "A"  ; 0x0112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
}
