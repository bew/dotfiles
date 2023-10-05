#Requires AutoHotkey v2.0

; FIXME: not tested with AHK v2
; Find and toggle matching window, or launch one if it doesn't exist.
; Returns true if window is now visible, false otherwise.
ToggleWinVisibilityOrLaunch(window_selector, window_launch)
{
    if WinExist(window_selector) {
        if WinActive(window_selector) {
            WinMinimize
            return false
        } else {
            WinActivate
            return true
        }
    } else {
        Run(window_launch)
        WinWaitActive(window_selector)
        return true
    }
}

; FIXME: not tested with AHK v2
; Returns absolute position of mouse cursor.
GetMousePos()
{
    ; Required to get absolute mouse pos (across all visible monitors)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouse_x, &mouse_y)
    return {x: mouse_x, y: mouse_y}
}

; Move the window to be centered on the given (absolute) position.
MoveWinCenteredOn(window_selector, pos)
{
    WinGetPos(&_win_x, &_win_y, &win_width, &win_height, window_selector)
    WinMove(pos.x - (win_width//2), pos.y - (win_height//2), win_width, win_height, window_selector)
}

; Returns absolute (and win relative) position of the center of the window.
GetWinCenterPos(window_selector)
{
    WinGetPos(&win_x, &win_y, &win_width, &win_height, window_selector)
    ; rel: relative to the window
    rel_center_x := (win_width//2)
    rel_center_y := (win_height//2)
    ; abs: absolute to the screen (across all visible monitors)
    abs_center_x := win_x + rel_center_x
    abs_center_y := win_y + rel_center_y
    return {
        x: abs_center_x,
        y: abs_center_y,
        win_relative_x: rel_center_x,
        win_relative_y: rel_center_y,
    }
}

; Returns monitor info of the monitor including the given absolute position,
; or false if position is offscreen.
GetMonitorIncludingPos(pos)
{
    monitor_count := SysGet(80) ; count only VISIBLE display monitors (not exactly same as MonitorGetCount)
    Loop monitor_count ; NOTE: indices always start at 1
    {
        ; Get the total desktop space of the monitor, including taskbar
        MonitorGet(A_Index, &mon_left, &mon_top, &mon_right, &mon_bottom)

        if (mon_left <= pos.x) && (pos.x < mon_right) && (mon_top <= pos.y) && (pos.y < mon_bottom) {
            return GetMonitorInfo(A_Index)
        }
    }
    return false ; can happen if pos is offscreen (e.g: partially visible window)
}

; Returns monitor info of the given monitor index (used by GetMonitorIncludingPos).
; NOTE: workarea coords are absolute to the screen (across all visible monitors)
GetMonitorInfo(monitor_index)
{
    name := MonitorGetName(monitor_index)
    MonitorGetWorkArea(monitor_index, &workareaLeft, &workareaTop, &workareaRight, &workareaBottom)
    workarea_center_x := workareaLeft + (workareaRight - workareaLeft) // 2
    workarea_center_y := workareaTop + (workareaBottom - workareaTop) // 2
    ; NOTE on associative arrays: https://www.autohotkey.com/docs/Objects.htm#Usage_Associative_Arrays
    workarea := {left: workareaLeft, right: workareaRight, top: workareaTop, bottom: workareaBottom}
    workarea_center_pos := {x: workarea_center_x, y: workarea_center_y}
    return {index: monitor_index, name: name, workarea: workarea, center_pos: workarea_center_pos}
}
