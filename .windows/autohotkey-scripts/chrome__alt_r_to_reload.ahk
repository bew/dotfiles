; In Google Chrome: Map Alt+r to reload page

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

#IfWinActive Chrome
; ! is Alt

; Alt+r -> F5
!r::Send {F5}
