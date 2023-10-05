; In web browsers: General tab/page control
#Requires AutoHotkey v2.0
#SingleInstance Force

; ! is Alt
; ^ is Ctrl
; + is Shift

GroupAdd("Browsers", "ahk_exe chrome.exe")
GroupAdd("Browsers", "ahk_exe msedge.exe") ; Microsoft Edge
GroupAdd("Browsers", "Firefox")
#HotIf WinActive("ahk_group Browsers")


; --- History previous/next

; NOTE: it does not seem to work well when doing the mapping twice+ in a row
; (without releasing ctrl), while using caps2ctrl-esc for ctrl.

; Ctrl+Alt+a -> Alt+Left
^!a::Send "!{Left}"
; Ctrl+Alt+z -> Alt+Right
^!z::Send "!{Right}"

; --- Switch prev/next tab

; Alt+a -> Ctrl+Shift+tab
!a::Send "^+{Tab}"
; Alt+z -> Ctrl+tab
!z::Send "^{Tab}"

; --- Close current tab
; Alt+d -> Ctrl+w
!d::Send "^w"

; --- Reload page
; Alt+r -> F5
!r::Send "{F5}"

; --- Reopen closed tab
; Alt+u -> Ctrl+Shift+t
!u::Send "^+t"

; --------------------------
; Key remaps for easier access

; Alt+Ctrl+j -> {Enter}
!^j::Send "{Enter}"
; It would be nice to have Ctrl+j only, but since it's a key
; already used by Chrome (for downloads), we use Alt+Ctrl+j and I think it will
; better fit with the rest of the shortcuts since I use Alt everywhere for my
; own keybinds.
