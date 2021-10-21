; In Google Chrome: Map Alt+u to reopen closed tab

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

#IfWinActive Chrome
; ! is Alt
; ^ is Ctrl
; + is Shift

; Alt+u -> Ctrl+Shift+t
!u::Send ^+t
