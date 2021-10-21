; Move the window to the mouse cursor.
; It will be exactly at the center of the window.
MoveWinToCursor(window_selector)
{
  WinGetPos,,, win_width, win_height, %window_selector%
  CoordMode, Mouse, Screen ; Required to get mouse pos relative to the screen
  MouseGetPos, xpos, ypos
  WinMove, %window_selector%,, xpos-(win_width/2), ypos-(win_height/2)
}

; Raise the window if it exists, or launch it,
; then place it under mouse cursor.
RaiseWinToCursorOrLaunch(window_selector, window_launch)
{
  If WinExist(window_selector)
  {
    If WinActive(window_selector)
    {
      WinMinimize
    }
    Else
    {
      WinActivate
      MoveWinToCursor(window_selector)
    }
  }
  Else
  {
    Run, %window_launch%
    WinWaitActive, %window_selector%
    MoveWinToCursor(window_selector)
  }
}
