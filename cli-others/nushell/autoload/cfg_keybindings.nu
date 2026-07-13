$env.config.edit_mode = "vi"

# Useful commands:
# - keybindings list
# - keybindings listen
$env.config.keybindings = [
  # FIXME: I want more menu actions:
  #   - `MenuCancel`, to cancel the menu without going to normal mode!
  #   - `MenuAcceptHold` to accept current menu selection without closing menu
  #   => Created: https://github.com/nushell/reedline/issues/767

  # FIXME: Add `InsertLine{Below,Above}` for Alt-o/O
  # ...

  # Ctrl-j -> Enter
  {
    name: accept-cmd--linux
    mode: [emacs vi_insert vi_normal]
    modifier: Control keycode: Char_j
    event: { send: Enter }
  }
  {
    # NOTE: On Windows, `Ctrl-j` is recognized as `Ctrl-Enter` 👀
    name: accept-cmd--win
    mode: [emacs vi_insert vi_normal]
    modifier: Control keycode: Enter
    event: { send: Enter }
  }

  # Alt-hjkl -> Left/Down/Up/Right navigation
  {
    name: move_up
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_k
    event: {
      until: [ # try actions until one works
        {send: MenuUp}
        {send: Up}
      ]
    }
  }
  {
    name: move_down
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_j
    event: {
      until: [ # try actions until one works
        {send: MenuDown}
        {send: Down}
      ]
    }
  }
  {
    name: move_left
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_h
    event: {
      until: [ # try actions until one works
        {send: MenuLeft}
        {send: Left}
      ]
    }
  }
  {
    name: move_right
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_l
    event: {
      until: [ # try actions until one works
        {send: MenuRight}
        {send: Right}
      ]
    }
  }

  # Alt-b/w/e/B/W/E -> Left/Right (big) word movement
  {
    name: move_to_prev_word
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_b
    event: {edit: MoveWordLeft}
  }
  {
    name: move_to_next_word_or_take_history_word_hint
    mode: [emacs vi_insert] # NOTE: insert only
    modifier: Alt keycode: Char_w
    event: {
      until: [ # try actions until one works
        {send: HistoryHintWordComplete}
        {edit: MoveWordRightStart}
      ]
    }
  }
  {
    name: move_to_next_word
    mode: [vi_normal] # NOTE: normal only
    modifier: Alt keycode: Char_w
    event: {edit: MoveWordRight}
  }
  {
    name: move_to_end_word
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_e
    # FIXME(BUG): In insert mode, goes to char before end of word
    event: {edit: MoveWordRightEnd}
  }
  {
    name: move_to_prev_WORD
    mode: [emacs vi_insert vi_normal]
    modifier: Alt_Shift keycode: Char_B
    event: {edit: MoveBigWordLeft}
  }
  {
    name: move_to_next_WORD
    mode: [emacs vi_insert vi_normal]
    modifier: Alt_Shift keycode: Char_W
    event: {edit: MoveBigWordRightStart}
  }
  {
    name: move_to_end_WORD
    mode: [emacs vi_insert vi_normal]
    modifier: Alt_Shift keycode: Char_E
    # FIXME(BUG): In insert mode, goes to char before end of word
    event: {edit: MoveBigWordRightEnd}
  }

  # Alt-^/$ -> Start/End of line movement
  {
    name: move_to_line_start
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_^
    event: {edit: MoveToLineStart}
  }
  {
    name: move_to_line_end_or_take_history_hint
    mode: [emacs vi_insert vi_normal]
    modifier: Alt keycode: Char_$
    event: {
      until: [ # try actions until one works
        {send: historyhintcomplete}
        {edit: MoveToLineEnd}
      ]
    }
  }

  # Cutting actions
  {
    name: cut_line_to_start # want: cut_line_to_line_start
    mode: [vi_insert]
    modifier: Control keycode: Char_u
    # FIXME: I want to cut from cursor to BOL, not beginning of buffer!
    event: {edit: CutFromStart}
  }
  {
    name: cut_left_word
    mode: [emacs vi_insert]
    modifier: Alt keycode: Backspace
    event: {edit: CutWordLeft}
  }

  # Alt-u/U -> Undo/Redo
  {
    name: undo
    mode: [vi_insert vi_normal]
    modifier: Alt keycode: Char_u
    event: {edit: Undo}
  }
  {
    name: redo
    mode: [vi_insert vi_normal]
    modifier: Alt_Shift keycode: Char_u
    event: {edit: Redo}
  }

  # ------------------------------------------------

  {
    name: unfreeze_last_job
    mode: [vi_insert vi_normal]
    modifier: Control keycode: Char_z
    event: {
      send: ExecuteHostCommand
      cmd: "if not (jobs any?) { print '' }; fg last"
    }
  }
  {
    name: unfreeze_before_last_job
    mode: [vi_insert vi_normal]
    modifier: Control_Alt keycode: Char_z
    event: {
      send: ExecuteHostCommand
      cmd: "if not (jobs any?) { print '' }; fg before-last"
    }
  }

  # ------------------------------------------------

  {
    name: git_status
    mode: [vi_insert vi_normal]
    modifier: Alt keycode: Char_g
    event: {
      send: ExecuteHostCommand
      # Need that early `print` to ensure command starts on a fresh line
      # NOTE: a better solution would be a `commandline cursor --after-prompt`
      cmd: "print ''; git status"
    }
  }
  {
    name: git_diff
    mode: [vi_insert vi_normal]
    modifier: Alt keycode: Char_d
    event: {
      send: ExecuteHostCommand
      cmd: "git d"
    }
  }
  {
    name: git_diff_staged
    mode: [vi_insert vi_normal]
    modifier: Alt_Shift keycode: Char_d
    event: {
      send: ExecuteHostCommand
      cmd: "git d --cached"
    }
  }

  # FIXME: How to implement 'go right or git log?' (maybe via 'until'?)
]
