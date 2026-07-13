; In Firefox web browser: Extra keys for tab/page control
#Requires AutoHotkey v2.0
#SingleInstance Force

; ! is Alt
; ^ is Ctrl
; + is Shift

#HotIf WinActive("Firefox")

; Doc for FF keybinds:
; https://support.mozilla.org/en-US/kb/keyboard-shortcuts-perform-firefox-tasks-quickly


; --- Move tab left/right

; Ctrl+Shift+a -> Ctrl+Shift+PageUp
^+a::Send "^+{PgUp}"
; Ctrl+Shift+z -> Ctrl+Shift+PageDown
^+z::Send "^+{PgDn}"

; --- Reopen closed window
; Ctrl+Alt+u -> Ctrl+Shift+n
^!u::Send "^+n"
