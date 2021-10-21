; In Google Chrome: Map Alt+a & Alt+z to switch prev/next tab

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

#IfWinActive Chrome
; ! is Alt
; ^ is Ctrl
; + is Shift

; Alt+a -> Ctrl+Shift+tab
!a::Send ^+{Tab}

; Alt+z -> Ctrl+tab
!z::Send ^{Tab}
