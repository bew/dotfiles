; In Google Chrome: Map Alt+d to close current tab

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

#IfWinActive Chrome
; ! is Alt
; ^ is Ctrl

; Alt+d -> Ctrl+w
!d::Send ^w
