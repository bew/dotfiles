; Map Win+Ctrl+s to open the Windows screenshot/snipping tool

#SingleInstance

; #: Windows key
; +: Shift key
; ^: Ctrl key

; Win+Ctrl+s -> Win+Shift+s
#^s::Send #+s

; NOTE: There's another AHK remap, Win+Shift+s that instead remaps to something else. These two may conflict with each other (this remap would go through ahk remap again).
; However in my testing, the keymaps doesn't seems to conflict.. so.. all good! ;)
