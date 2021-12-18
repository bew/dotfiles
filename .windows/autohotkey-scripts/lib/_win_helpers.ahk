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

; Returns absolute (and win relative) position of the center of the window.
GetWinCenterPos(window_selector)
{
  WinGetPos, win_x, win_y, win_width, win_height, %window_selector%
  ; rel: relative to the window
  rel_center_x := (win_width//2)
  rel_center_y := (win_height//2)
  ; abs: absolute to the screen (across all visible monitors)
  abs_center_x := win_x + rel_center_x
  abs_center_y := win_y + rel_center_y
  return {x: abs_center_x, y: abs_center_y, win_relative_x: rel_center_x, win_relative_y: rel_center_y}
}
