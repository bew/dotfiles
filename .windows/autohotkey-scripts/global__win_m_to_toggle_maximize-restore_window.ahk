; Map Win-m to toggle maximization of current window

#SingleInstance Force

; #: Window key

#m::
  WinGet is_min_max, MinMax, A
  if (is_min_max == 1) {
    WinRestore A
  } else {
    WinMaximize A
  }
