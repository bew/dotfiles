; Map Capslock to Escape on tap or to Control with another key

#SingleInstance Force

; https://www.autohotkey.com/docs/Hotkeys.htm#Symbols
; * (Modifier) Fire the hotkey even if extra modifiers are being held down. This is often used in conjunction with remapping keys or buttons
; A_PRIORKEY The name of the last key which was pressed prior to the most recent key-press or key-release, or blank if no applicable key-press can be found in the key history.
;
; Inspired by https://github.com/fenwar/ahk-caps-ctrl-esc/blob/775d46f4d3a92907d08558b1db3f77bb0ef85720/AutoHotkey.ahk
;
; Workflow:
;   Caps + key -> Ctrl + key
;   Caps tap   -> Ctrl tap then Escape tap
;
; If Caps is held down more than 500ms, release won't register as a tap

CapsDownStart := -1

*Capslock::

Send {Blind}{LControl down}
if (CapsDownStart == -1)
    CapsDownStart := A_TickCount
return


*Capslock up::

Send {Blind}{LControl up}
CapsDownTime := A_TickCount - CapsDownStart
CapsDownStart := -1
if (A_PRIORKEY == "CapsLock" && CapsDownTime < 500)
{
  ; NOTE: For Skype, sending Escape closes the window.. I didn't find how to remap
  ; the Escape key sent by this script (should be sth with SendLevel/InputLevel),
  ; So in the meantime we do this check here to NOT send Escape for Skype windows.
  IfWinActive, ahk_exe lync.exe ; Any Skype window
  {
    return
  }
  Else
  {
    ; In ALL other cases, send the glorious Escape key :)
    Send {Esc}
  }
}
return
