; When the keyboard layout is configured to be international, typing ` and
; the OS waits the next key to decide what to do with the key and send it to
; the current application. ('``' sends '``', '`e' sends 'è', '`z' sends '`z', ...)
; To bypass this behavior, typing ` then space sends ONLY ` to the current app.
;
; So this AHK does exactly that, typing '`' will send '`' then 'Space'.
#Requires AutoHotkey v2.0
#SingleInstance Force

; <^>! is AltGr

<^>!è::Send "``{Space}"

; NOTE:
; - Mapping ` does nothing, so I map AltGr+è which is the combination to get '`'
;   on AZERTY keyboard layout.
; - Since AHK uses the backtick for some shortcut, I need to write '``' in AHK
;   to send '`' to the OS.
