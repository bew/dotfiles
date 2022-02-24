; Map Win+² to activate the last flashing window

#SingleInstance Force

; #: Window key
;
; Inspired from:
; - https://www.autohotkey.com/board/topic/54990-find-the-blinking-window-on-the-taskbar/
; - https://www.autohotkey.com/board/topic/36510-detect-flashingblinking-window-on-taskbar/

; --- System plumbing

; Get the script's "window"
Script_PID := DllCall("GetCurrentProcessId") ; doc in: https://www.autohotkey.com/docs/commands/Process.htm#Exist
DetectHiddenWindows, On
Script_WinHandle := WinExist("ahk_class AutoHotkey ahk_pid " . Script_PID)
DetectHiddenWindows, Off

; Register a Shell hook on the script's "window" to detect flashing windows
; Doc: https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registershellhookwindow
DllCall("RegisterShellHookWindow", "uint", Script_WinHandle)
; (See Remarks in doc of RegisterShellHookWindow for why we need this call)
MsgIdForShellHook := DllCall("RegisterWindowMessage", "str", "SHELLHOOK")
; Register my AHK function to be called when the script's 'window' receives a shell hook message
OnMessage(MsgIdForShellHook, "MyShellCallback")

; --- My code

LastFlashingWinHandle := -1

MyShellCallback(wParam, lParam) {
    ; HSHELL_FLASH is described in:
    ; https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registershellhookwindow#remarks
    if (wParam == 0x8006) { ; 0x8006 is HSHELL_FLASH
        ; lParam contains the ID of the window which flashed:
        global LastFlashingWinHandle ; allow to change a global var
        LastFlashingWinHandle := lParam
    }
}

; For some reason, mapping '²' does not work in this script although it
; works in './global__shift-mini2_to_tilde.ahk'...
;
; So we map the virtual key 'DE', referenced as 'VKDE'.
; (see: https://www.autohotkey.com/docs/KeyList.htm#SpecialKeys)
#VKDE::
  if (LastFlashingWinHandle != -1) {
    WinActivate, ahk_id %LastFlashingWinHandle%
    ; Reset last flashing win
    global LastFlashingWinHandle ; allow to change a global var
    LastFlashingWinHandle := -1
  } else {
    ToolTip, No last flashing window...
    Sleep 1000 ; 1s
    ToolTip ; Set current tooltip to blank, removing it
  }
  return
