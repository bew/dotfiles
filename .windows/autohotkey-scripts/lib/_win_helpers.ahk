; Move the window to be centered on the given (absolute) position.
MoveWinCenteredOn(window_selector, pos)
{
  WinGetPos,,, win_width, win_height, %window_selector%
  WinMove, %window_selector%,, pos.x - (win_width//2), pos.y - (win_height//2)
}

; Find and toggle matching window, or launch one if it doesn't exist.
; Returns true if window is now visible, false otherwise.
ToggleWinVisibilityOrLaunch(window_selector, window_launch)
{
  If WinExist(window_selector)
  {
    If WinActive(window_selector)
    {
      WinMinimize
      return false
    }
    Else
    {
      WinActivate
      return true
    }
  }
  Else
  {
    Run, %window_launch%
    WinWaitActive, %window_selector%
    return true
  }
}

; Returns absolute position of mouse cursor.
GetMousePos()
{
  ; Required to get absolute mouse pos (across all visible monitors)
  CoordMode, Mouse, Screen
  MouseGetPos, mouse_x, mouse_y
  return {x: mouse_x, y: mouse_y}
}
