; In Google Chrome: Map Alt+Ctrl+j to Enter

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

#IfWinActive Chrome
; ! is Alt
; ^ is Ctrl

; Alt+Ctrl+j -> {Enter}
!^j::Send {Enter}

; It would be nice to have Ctrl+j only, but since it's a key
; already used by Chrome, we use Alt+Ctrl+j and I think it will
; better fit with the rest of the shortcuts since I use Alt
; everywhere for my own keybinds.
