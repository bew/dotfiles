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

; Returns monitor info of the monitor including the given absolute position,
; or false if position is offscreen.
GetMonitorIncludingPos(pos)
{
  SysGet, monitor_count, 80 ; count only visible display monitors (not exactly same as MonitorCount)
  Loop, %monitor_count% ; NOTE: indices always start at 1
  {
    ; Get the total desktop space of the monitor, including taskbar
    SysGet, monitor, Monitor, %A_Index%

    if (monitorLeft <= pos.x) && (pos.x < monitorRight) && (monitorTop <= pos.y) && (pos.y < monitorBottom) {
      return GetMonitorInfo(A_Index)
    }
  }
  return false ; can happen if pos is offscreen (e.g: partially visible window)
}

; Returns monitor info of the given monitor index (used by GetMonitorIncludingPos).
; NOTE: workarea coords are absolute to the screen (across all visible monitors)
GetMonitorInfo(monitor_index)
{
  SysGet, name, MonitorName, %monitor_index%
  SysGet, workarea, MonitorWorkArea, %monitor_index%
  workarea_center_x := workareaLeft + (workareaRight - workareaLeft) // 2
  workarea_center_y := workareaTop + (workareaBottom - workareaTop) // 2
  ; NOTE on associative arrays: https://www.autohotkey.com/docs/Objects.htm#Usage_Associative_Arrays
  workarea := {left: workareaLeft, right: workareaRight, top: workareaTop, bottom: workareaBottom}
  workarea_center_pos := {x: workarea_center_x, y: workarea_center_y}
  return {index: monitor_index, name: name, workarea: workarea, center_pos: workarea_center_pos}
}
