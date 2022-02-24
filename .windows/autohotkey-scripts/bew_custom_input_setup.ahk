; In various apps: Load custom inputs (based on Alt+xyz)

; ! is Alt
; ^ is Ctrl
; + is Shift

#SingleInstance Force

SetTitleMatchMode 2 ; match on partial substring

GroupAdd, bew_input, ahk_exe chrome.exe
GroupAdd, bew_input, ahk_exe lync.exe ; Skype
GroupAdd, bew_input, ahk_exe Teams.exe
GroupAdd, bew_input, ahk_exe Outlook.exe
GroupAdd, bew_input, ahk_exe Mattermost.exe
GroupAdd, bew_input, Firefox

; Windows Explorer and parts of the Windows's Shell (the desktop environment)
; NOTE: I can't get arrows to work on the clipboard manager to move up/down because when
;       pressing Alt for Alt+{j,k}, the popup disappears. I also tried to map Win+{j,k}
;       so I can do Win+v then Win+j to go down, but 'Down' isn't passed to the clipboard
;       manager's window but the window behind it :/
GroupAdd, bew_input, ahk_exe Explorer.exe

#IfWinActive ahk_group bew_input

; --- Word movement

; Alt+{b,w} -> Ctrl+{Left,Right}
!b::Send ^{Left}
!w::Send ^{Right}
; With Shift to select
!+b::Send ^+{Left}
!+w::Send ^+{Right}

; --- Begin/End of page/text

; Alt+g -> Ctrl+Home (Begin)
!g::Send ^{Home}
; Alt+Shift+g -> Ctrl+End
!+g::Send ^{End}

; --- Begin/End of line

; Alt+^ -> Home
; NOTE: VKDD is the virtual key for ^ on azerty layout (key left of $)
!VKDD::Send {Home}
; With Shift to select
!+VKDD::Send +{Home}

; Alt+$ -> End
!$::Send {End}
; With Shift to select
!+$::Send +{End}

; --- Arrows

; Alt+{h,j,k,l} -> {Left,Down,Up,Right}
!h::Send {Left}
!j::Send {Down}
!k::Send {Up}
!l::Send {Right}
; With Shift to select
!+h::Send +{Left}
!+j::Send +{Down}
!+k::Send +{Up}
!+l::Send +{Right}

; --- New line above/below
; Simulates vim's o/O to insert a new line above/below from anywhere on the line.
; It uses Shift+Enter instead of plain Enter to avoid sending msg in tchat
;   textboxes and ensures it makes a new line.
;   I checked, it works in chrome, skype, outlook. And it should work in others.

; Alt+o -> End then Shift+Enter (new line below)
!o::
  Send {End}
  Send +{Enter}
  return

; Alt+Shift+o -> Home then Shift+Enter then Up (new line above)
!+o::
  Send {Home}
  Send +{Enter}
  Send {Up}
  return

; --- Quick retry that line

; Ctrl+u -> Shift+Home (select) then Backspace (delete)
^u::
  Send +{Home}
  Sleep 100 ; 100ms, for (minimal) visual feedback
  Send {Backspace}
  return
