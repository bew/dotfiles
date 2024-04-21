use bewcfg_theme.nu
use default_config.nu get_default_config

export def get_config [] {
  let default_cfg = get_default_config

  mut cfg = {}
  $cfg.show_banner = false
  $cfg.color_config = (bewcfg_theme get_my_theme)

  $cfg.ls = {
    use_ls_colors: true
    clickable_links: false
  }

  $cfg.cursor_shape = {
    emacs: line
    vi_insert: line
    vi_normal: block
  }

  # External completer example
  # let carapace_completer = {|spans|
  #     carapace $spans.0 nushell $spans | from json
  # }

  $cfg.completions = ($default_cfg.completions | merge {
    # FIXME: The 'fuzzy' algorithm is ~useless, there is no scoring system to prioritize matches
    # algorithm: "fuzzy" # prefix or fuzzy
  })

  $cfg.menus = [
    # Configuration for default nushell menus
    # Note the lack of source parameter
    {
      name: completion_menu
      only_buffer_difference: false
      marker: " ? "
      type: {
        layout: columnar
        columns: 4
        # col_width: 20 # Use all screen width
        col_padding: 2
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
    }
    {
      name: history_menu
      only_buffer_difference: true
      marker: " ? "
      type: {
        layout: list
        page_size: 10
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
    }
    {
      name: help_menu
      only_buffer_difference: true
      marker: " ? "
      type: {
        layout: description
        columns: 4
        col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
        col_padding: 2
        selection_rows: 4
        description_rows: 10
      }
      style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
      }
    }
  ]

  $cfg.edit_mode = vi

  # Useful commands:
  # - keybindings list
  # - keybindings listen
  $cfg.keybindings = ($default_cfg.keybindings | append [
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
      name: git_status
      mode: [vi_insert vi_normal]
      modifier: Alt keycode: Char_g
      event: {
        send: ExecuteHostCommand
        # Need `echo` to ensure command starts on a fresh line
        # NOTE: a better solution would be a `commandline cursor --after-prompt`
        cmd: "echo; git status"
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
  ])

  $cfg
}
