; Map Win+Shift+s to move current window to another screen
#Requires AutoHotkey v2.0
#SingleInstance

; #: Windows key
; +: Shift key

; Win+Shift+s -> Win+Shift+Right
#+s::Send "#+{Right}"

; There's another AHK remap, Win+Ctrl+s, which remaps to Win+Shift+s (this remap) that may conflicts.
; However in my testing, the keymaps doesn't seems to conflict.. so.. all good! ;)
