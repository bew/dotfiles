; In Google Chrome: Map Ctrl+Alt+a & Ctrl+Alt+z for history previous/next

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

#IfWinActive Chrome
; ! is Alt
; ^ is Ctrl
; + is Shift

; Ctrl+Alt+a -> Alt+Left
^!a::Send !{Left}

; Ctrl+Alt+z -> Alt+Right
^!z::Send !{Right}

; NOTE: it does not seem to work well when doing the mapping
; twice+ in a row (without releasing ctrl)
