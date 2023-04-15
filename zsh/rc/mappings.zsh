#----------------------------------------------------------------------------------
# ZLE Widgets
#----------------------------------------------------------------------------------

# TODO: find a way (kinda profiles?) to split utils/mappings between:
# * shell-specific (like zle::utils::no-history-run, zwidget::force-scroll-window or zwidget::fg)
# * common-cli-specific (like zwidget::git-diff, zwidget::fzf::z or zwidget::toggle-sudo-nosudo)
#
# => Where to put clipboard stuff? in a seperate plugin? (mostly specific to my setup then)


# Checks if we are in a git repository, displays a ZLE message otherwize.
function zle::utils::check_git
{
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    zle -M "Error: Not a git repository"
    return 1
  fi
}

# Run the given command from a zle widget, as if it was written by the user
# but without saving it to the history.
#
# Limitation: does not compose well, we can't easily run another command or
#   display some arbitrary text after the command is run..
function zle::utils::no-history-run
{
  local cmd="$1"

  # Push current buffer, will be auto restored after $cmd
  zle push-input

  BUFFER=" $cmd" # skip history with a leading space
  zle .accept-line
}

function zle::utils::is-insert-mode
{
  [[ "$KEYMAP" =~ "(main|viins)" ]]
}

# Set $REPLY with the current vim mode (insert, normal, visual*, replace)
function zle::utils::get-vim-mode
{
  if [[ -z $KEYMAP ]]; then
    REPLY="insert"
    return
  fi
  if [[ "$KEYMAP" =~ "(main|viins)" ]] && [[ $ZLE_STATE == *insert* ]]; then
    REPLY="insert"
  elif [[ "$KEYMAP" =~ "(main|viins)" ]] && [[ $ZLE_STATE == *overwrite* ]]; then
    REPLY="replace"
  elif [[ "$KEYMAP" == "vicmd" ]] && [[ "$REGION_ACTIVE" == 0 ]]; then
    REPLY="normal"
  elif [[ "$KEYMAP" == "vicmd" ]] && [[ "$REGION_ACTIVE" == 1 ]]; then
    # NOTE: does not work, we're NOT notified on normal<=>visual mode change
    REPLY="visualchar"
  elif [[ "$KEYMAP" == "vicmd" ]] && [[ "$REGION_ACTIVE" == 2 ]]; then
    # NOTE: does not work, we're NOT notified on normal<=>visual mode change
    REPLY="visualline"
  else
    REPLY="unknown"
  fi
}

# Get the row (0-indexed) the cursor is on (in a multi-lines buffer)
function zle::utils::get-cursor-row0-in-buffer
{
  local cursor_row0_in_buffer=0
  for (( i=1; i<=$#LBUFFER; i++ )); do
    [[ ${LBUFFER[$i]} == $'\n' ]] && (( cursor_row0_in_buffer += 1 ))
  done
  REPLY_cursor_row0_in_buffer=$cursor_row0_in_buffer
}

function zle::term-utils::get-cursor-pos
{
  # Inspired from: https://www.zsh.org/mla/users/2015/msg00866.html
  # It seems to work well :) (unlike my own old impl from a long time ago)
  local pos="" char
  print -n $'\e[6n' # Ask terminal for cursor position
  # Then read char by char until we get a 'R'
  # (terminal reply looks like: `\e[57;12R`)
  while read -r -s -k1 char; do
    [[ $char == R ]] && break
    pos+=$char
  done
  pos=${pos#*\[} # remove '\e['

  # pos has format 'row;col'
  REPLY_cursor_row_in_term=${pos%;*} # remove ';col'
  REPLY_cursor_col_in_term=${pos#*;} # remove 'row;'
}

# NOTE: when implemented in terminals, we can have '...reveal-scrollback-by' !
function zle::term-utils::hide-scrollback-by
{
  local by_rows="${1:-1}" # default to 1 line
  [[ "$by_rows" == 0 ]] && return

  echo -n $'\e['"${by_rows}S" >/dev/tty # Scroll the terminal
  echo -n $'\e['"${by_rows}A" >/dev/tty # Move the cursor back up
}

# --------

# Toggle between "nosudo "/"sudo "/"" at <bol>
function zwidget::toggle-sudo-nosudo # TODO: refactor to a re-usable function
{
  # Overwriting BUFFER will reset CURSOR to <bol>
  # so we store its original position first
  local saved_cursor=$CURSOR

  local remove_text
  local add_text

  # Cycle <bol>: "nosudo " > "sudo " > ""
  if [[ "${BUFFER[1, 7]}" == "nosudo " ]]; then
    remove_text="nosudo "
    add_text="sudo "
  elif [[ "${BUFFER[1, 5]}" == "sudo " ]]; then
    remove_text="sudo "
  else
    add_text="nosudo "
  fi

  if [[ -n "$remove_text" ]]; then
    BUFFER="${BUFFER[${#remove_text} + 1, ${#BUFFER}]}"
    (( CURSOR = saved_cursor - ${#remove_text} ))
    (( saved_cursor = CURSOR )) # needed if -n "$add_text"
  fi
  if [[ -n "$add_text" ]]; then
    BUFFER="${add_text}$BUFFER"
    (( CURSOR = saved_cursor + ${#add_text} ))
  fi

  zle redisplay
}
zle -N zwidget::toggle-sudo-nosudo
# TODO: is there a way to handle commands not at <bol> ? (mapped to M-S instead of M-s)
# e.g: echo 400 | [NEED TOGGLE SUDO HERE] tee /foo/bar

# Force scroll the window to give some space for the prompt
#
# It's not technically required, but it sometimes help to have blank lines
# to think about things..
function zwidget::force-scroll-window
{
  # Don't attempt to scroll in a tty
  [ "$TERM" = "linux" ] && return

  zle::term-utils::hide-scrollback-by 10

  zle redisplay
}
zle -N zwidget::force-scroll-window

# When set, git-related key mappings will show status/log/diff for the current
# directory instead of the whole repo.
GIT_MAPPINGS_ARE_FOR_CWD="${GIT_MAPPINGS_ARE_FOR_CWD:-}"

# Git status (for repo or cwd)
function zwidget::git-status
{
  zle::utils::check_git || return

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    zle::utils::no-history-run "git status"
  else
    # Start by checking if there are staged files OUTSIDE of cwd,
    # If so, print _visible_ warning, to avoid committing stuff by mistakes while we're only looking
    # at CWD git status.
    local repo_nb_staged=$(git status --porcelain=v1 --untracked-files=no   |grep '^[^ ]' --count)
    local  cwd_nb_staged=$(git status --porcelain=v1 --untracked-files=no . |grep '^[^ ]' --count)
    if (( repo_nb_staged != cwd_nb_staged )); then
      echo # newline to 'step out' of current prompt
      echo
      local diff_staged_files=$(( repo_nb_staged - cwd_nb_staged ))
      local warn_msg="$diff_staged_files staged file(s) outside of CWD"
      local col_reset=$'\e[0m' col_yellow_bold=$'\e[1;33m' col_red_bold=$'\e[1;31m'
      echo -e "${col_red_bold}!!!${col_yellow_bold} WARNING: $warn_msg ${col_red_bold}!!!${col_reset}"
      echo
    fi
    zle::utils::no-history-run "git status .  # for cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
  fi
}
zle -N zwidget::git-status

# Git log (for repo or cwd)
function zwidget::git-log
{
  zle::utils::check_git || return

  local cmd=(git pretty-log --all)
  cmd+=(--max-count 100) # don't show too many commits to avoid waiting

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    "${cmd[@]}"
    zle reset-prompt
  else
    "${cmd[@]}" .
    zle reset-prompt
    zle -M "!! WARNING: Shown git logs are for cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
  fi
}
zle -N zwidget::git-log

# Git log (always for repo, never for cwd)
function zwidget::git-log-always-for-repo
{
  # Ensure git log call is for the whole repo
  GIT_MAPPINGS_ARE_FOR_CWD= zwidget::git-log
}
zle -N zwidget::git-log-always-for-repo

# Git diff (for repo or cwd)
function zwidget::git-diff
{
  zle::utils::check_git || return

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    git d
    zle reset-prompt
  else
    git d .
    zle reset-prompt
    zle -M "!! WARNING: Shown git diff is for cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
  fi
}
zle -N zwidget::git-diff

# Git diff cached (for repo or cwd)
function zwidget::git-diff-cached
{
  zle::utils::check_git || return

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    git dc
    zle reset-prompt
  else
    git dc .
    zle reset-prompt
    zle -M "!! WARNING: Shown git diff (cached) is for cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
  fi
}
zle -N zwidget::git-diff-cached

# FG to the most recent ctrl-z'ed process
# fg %+
function zwidget::fg
{
  [[ $#jobstates == 0 ]] && zle -M "No running jobs" && return

  zle::utils::no-history-run "fg %+"
}
zle -N zwidget::fg

# FG to the 2nd most recent ctrl-z'ed process
# fg %-
function zwidget::fg2
{
  [[ $#jobstates < 2 ]] && zle -M "Not enough running jobs" && return

  zle::utils::no-history-run "fg %-"
}
zle -N zwidget::fg2

# Cycle quoting for current argument
#
# Given this command, with the cursor anywhere on bar (or baz):
# $ cmd foo bar\ baz
#
# Multiple call to this widget will give:
# $ cmd foo 'bar baz'
# $ cmd foo "bar baz"
# $ cmd foo bar\ baz
function zwidget::cycle-quoting
{
  autoload -U modify-current-argument

  if [[ ! $WIDGET == $LASTWIDGET ]]; then
    # First call, or something else happened since last call
    # (e.g: the cursor moved)
    # => We're not in a change-quoting-method chain
    # => Reset quoting method
    ZWIDGET_CURRENT_QUOTING_METHOD=none
  fi

  function zwidget::cycle-quoting::inner
  {
    # ARG is the current argument in the cmdline

    # cycle order: none -> single -> double -> none

    local unquoted_arg="${(Q)ARG}"

    case "$ZWIDGET_CURRENT_QUOTING_METHOD" in
      none)
        # current: none
        # next: single quotes
        REPLY="${(qq)${unquoted_arg}}"
        ZWIDGET_CURRENT_QUOTING_METHOD=single
        ;;

      single)
        # current: single quotes
        # next: double quotes
        REPLY="${(qqq)${unquoted_arg}}"
        ZWIDGET_CURRENT_QUOTING_METHOD=double
        ;;

      double)
        # current: double quotes
        # next: no quotes (none)
        REPLY="${(q)${unquoted_arg}}"
        ZWIDGET_CURRENT_QUOTING_METHOD=none
        ;;
    esac
  }

  modify-current-argument zwidget::cycle-quoting::inner
  zle redisplay
}
zle -N zwidget::cycle-quoting

# Give a prompt where I can paste or write some text, it will then be single
# quoted (with escapes if needed) and inserted as a single argument.
function zwidget::insert_one_arg
{
  function read-from-minibuffer::no-syntax-hl
  {
    local default_maxlength="$ZSH_HIGHLIGHT_MAXLENGTH"
    ZSH_HIGHLIGHT_MAXLENGTH=0 # trick to disable syntax highlighting

    read-from-minibuffer $*
    local ret=$?

    ZSH_HIGHLIGHT_MAXLENGTH="$default_maxlength"
    return $ret
  }

  # NOTE: read-from-minibuffer's prompt is static :/ So no KEYMAP feedback
  autoload -Uz read-from-minibuffer
  read-from-minibuffer::no-syntax-hl 'Enter argument: ' || return 1
  [ -z "$REPLY" ] && return

  local quoted_arg="${(qq)${REPLY}}"

  # Insert argument in-place
  LBUFFER+="${quoted_arg}"
  zle redisplay
}
zle -N zwidget::insert_one_arg

# Jump to start of current/previous shell argument
#
# [z] means the CURSOR is on letter z
# [] means the CURSOR at the end of the BUFFER
# The BUFFER is between | and |
#
# |abc   de[f]|  =>  |abc   [d]ef|
# |abc   [d]ef|  =>  |[a]bc   def|
# |abc  [ ]def|  =>  |[a]bc   def|
#
# |   abc   def   []|  =>  |   abc   [d]ef   |
# |   abc   def [ ] |  =>  |   abc   [d]ef   |
# | [ ] abc   def   |  =>  |[ ]  abc   def   |
function zwidget::jump-previous-shell-arg
{
  autoload -U split-shell-arguments

  local reply REPLY REPLY2
  split-shell-arguments
  local word_idx=$REPLY char_idx_in_word=$REPLY2
  local sh_args=("${reply[@]}") # copy $reply array, keeping blank and empty elements
  (( char_idx0_in_word = char_idx_in_word - 1 )) # start idx at 0 instead of 1

  if (( word_idx == 1 )); then
    # CURSOR is on space before first argument
    # move CURSOR to start of everything
    (( CURSOR = 0 ))
    return
  fi

  # split-shell-arguments makes no difference between ('ab'[] and 'ab[ ]  '):
  # - the cursor is at the end of the buffer
  #  or
  # - the cursor is on the first char of a space after last shell argument
  #
  # Comparing $CURSOR and ${#BUFFER} is the only option here
  if (( CURSOR == ${#BUFFER} )); then
    # CURSOR is at the end of the buffer
    # in this case, split-shell-arguments makes:
    # - word_idx = idx of last space
    # - char_idx_in_word = 1 (<- not reliable)

    # move CURSOR to start of last space
    (( CURSOR = CURSOR - ${#sh_args[word_idx]} ))
    # move CURSOR to start of previous argument
    (( CURSOR = CURSOR - ${#sh_args[word_idx - 1]} ))
    return
  fi

  if (( word_idx % 2 != 0 )); then
    # CURSOR is on a space
    # move CURSOR to start of space
    (( CURSOR = CURSOR - char_idx0_in_word ))
    # move CURSOR to start of previous argument
    (( CURSOR = CURSOR - ${#sh_args[word_idx - 1]} ))
    return
  fi

  # Now CURSOR is on an argument

  if (( 0 < char_idx0_in_word )); then
    # CURSOR is somewhere on an argument, jump to start of it
    (( CURSOR = CURSOR - char_idx0_in_word ))
    return
  fi

  # Now CURSOR is at start of an argument

  if (( word_idx == 2 )); then
    # CURSOR is at start of first argument (the command), jump before first space
    (( CURSOR = 0 ))
    return
  fi

  # CURSOR is at start of an argument, jump to start of previous argument

  # move CURSOR to start of space before current argument
  (( CURSOR = CURSOR - ${#sh_args[word_idx - 1]}))
  # move CURSOR to start of previous argument
  (( CURSOR = CURSOR - ${#sh_args[word_idx - 2]}))
}
zle -N zwidget::jump-previous-shell-arg

# Jump to the next shell argument.
#
# [z] means the CURSOR is on letter z
# [] means the CURSOR at the end of the BUFFER
# The BUFFER is between | and |
#
# |[a]bc   def|  =>  |abc   [d]ef|
# |abc [ ] def|  =>  |abc   [d]ef|
# |abc   d[e]f|  =>  |abc   def[]|
#
# |[ ]  abc   def   |  =>  |   [a]bc   def   |
# |   abc   def [ ] |  =>  |   abc   def   []|
# |   abc   de[f]   |  =>  |   abc   def   []|
function zwidget::jump-next-shell-arg
{
  autoload -U split-shell-arguments

  local reply REPLY REPLY2
  split-shell-arguments
  local word_idx=$REPLY char_idx_in_word=$REPLY2
  local sh_args=("${reply[@]}") # copy $reply array, keeping blank and empty elements
  (( char_idx0_in_word = char_idx_in_word - 1 )) # start idx at 0 instead of 1

  if (( word_idx == ${#sh_args})); then
    # CURSOR is on space after last argument
    # move CURSOR after the end of the buffer
    (( CURSOR = ${#BUFFER} ))
    return
  fi

  if (( word_idx % 2 != 0 )); then
    # CURSOR is on a space
    # move CURSOR to start of next arg
    (( CURSOR = CURSOR - char_idx0_in_word + ${#sh_args[word_idx]} ))
    return
  fi

  # Now CURSOR is on an argument

  if (( char_idx_in_word <= ${#sh_args[word_idx]} )); then
    # CURSOR is on an argument, jump to next space
    (( CURSOR = CURSOR - char_idx0_in_word + ${#sh_args[word_idx]} ))
    # and skip next space
    (( CURSOR = CURSOR + ${#sh_args[word_idx + 1]} ))
    return
  fi
}
zle -N zwidget::jump-next-shell-arg

# Jump to the end of current/next shell argument.
# If we're in insert mode, put the cursor just after the end, to write AT the end.
#
# [z] means the CURSOR is on letter z
# [] means the CURSOR at the end of the BUFFER
# The BUFFER is between | and |
#
# |[a]bc   def|  =>  |ab[c]   def|
# |ab[c]   def|  =>  |abc   de[f]|
# |abc[ ]  def|  =>  |abc   de[f]|
#
# |[ ]  abc   def   |  =>  |   ab[c]   def   |
# |   abc   def [ ] |  =>  |   abc   def   []|
# |   abc   de[f]   |  =>  |   abc   def   []|
function zwidget::jump-end-shell-arg
{
  autoload -U split-shell-arguments

  local reply REPLY REPLY2
  split-shell-arguments
  local word_idx=$REPLY char_idx_in_word=$REPLY2
  local sh_args=("${reply[@]}") # copy $reply array, keeping blank and empty elements
  (( char_idx0_in_word = char_idx_in_word - 1 )) # start idx at 0 instead of 1

  if (( word_idx == ${#sh_args})); then
    # CURSOR is on space after last argument
    # move CURSOR after the end of the buffer
    (( CURSOR = ${#BUFFER} ))
    return
  fi

  if (( word_idx % 2 != 0 )); then
    # CURSOR is on a space
    # move CURSOR to the end of space
    (( CURSOR = CURSOR - char_idx_in_word + ${#sh_args[word_idx]} ))
    # move CURSOR to the end of next argument
    (( CURSOR = CURSOR + ${#sh_args[word_idx + 1]} ))
    # if in insert mode, ensure cursor is after the end (to write at the end)
    zle::utils::is-insert-mode && (( CURSOR = CURSOR + 1 ))
    return
  fi

  # Now CURSOR is on an argument

  if (( char_idx_in_word < ${#sh_args[word_idx]} )); then
    # CURSOR is somewhere on an argument (but not the end), jump to the end of it
    (( CURSOR = CURSOR - char_idx_in_word + ${#sh_args[word_idx]} ))
    # if in insert mode, ensure cursor is after the end (to write at the end)
    zle::utils::is-insert-mode && (( CURSOR = CURSOR + 1 ))
    return
  fi

  # Now CURSOR is at the end of an argument

  if (( word_idx == (${#sh_args} - 1) )); then
    # CURSOR is at the end of last argument, jump to the end of everything
    (( CURSOR = ${#BUFFER} ))
    return
  fi

  # CURSOR is at the end of an argument (not the last one), jump to the end of the next argument

  # move CURSOR to the end of space after current argument
  (( CURSOR = CURSOR + ${#sh_args[word_idx + 1]}))
  # move CURSOR to the end of next argument
  (( CURSOR = CURSOR + ${#sh_args[word_idx + 2]}))
  # if in insert mode, ensure cursor is after the end (to write at the end)
  zle::utils::is-insert-mode && (( CURSOR = CURSOR + 1 ))
  return
}
zle -N zwidget::jump-end-shell-arg

function zwidget::noop
{
  # do nothing!
}
zle -N zwidget::noop

# NOTE: Not perfect..
#   When completion menu is visible, it quits completion mode
#   (accepting current entry for some reason..)
#   --
#   Another idea to try could be to:
#   1. change the beginning of $PROMPT to call some binary to clear terminal with
#      content-preserving behavior
#   2. redisplay prompt
#   3. revert $PROMPT to what it was
#
# Nice writeup I made on how it works and why:
# https://github.com/wez/wezterm/issues/2405#issuecomment-1214418211
#
# TODO(?): Make a proper helper binary (in Rust?) or a zsh plugin to allow other
#          people to have this (generally wanted) behavior?
function zwidget::clear-but-keep-scrollback
{
  local REPLY_cursor_row_in_term REPLY_cursor_col_in_term
  zle::term-utils::get-cursor-pos

  local REPLY_cursor_row0_in_buffer
  zle::utils::get-cursor-row0-in-buffer

  local prompt_row=$(( REPLY_cursor_row_in_term - REPLY_cursor_row0_in_buffer ))
  zle::term-utils::hide-scrollback-by "$(( prompt_row - 1 ))"

  zle redisplay
  # zle -M "prompt row was: $prompt_row"
}
zle -N zwidget::clear-but-keep-scrollback

#-------------------------------------------------------------
# Mappings

# Enable vim mode
bindkey -v

#-------------------------------------------------------------
# Proper keys definitions

zmodload zsh/terminfo

# Make sure that the terminal is in application mode when zle is active, since
# only then values from `$terminfo` are valid.
#
# We don't always enable application mode since some terminal does not define
# smkx/rmkx terminfo entries (like the linux vt terminal).
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle::utils::enable-app-mode {
    echoti smkx
  }
  function zle::utils::disable-app-mode {
    echoti rmkx
  }
  hooks-add-hook zle_line_init_hook   zle::utils::enable-app-mode
  hooks-add-hook zle_line_finish_hook zle::utils::disable-app-mode
fi

# Helper commands to see which keys are sent in normal mode / application mode:
# For normal mode:
#   cat -e
# For application mode: (enables app mode first, and disable afterward)
#   printf "\x1b[?1h" ; cat -e ; printf "\x1b[?1l"
#
# Also some good doc on the 2 modes, and below the difference it means for some keys:
# https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#mode-changes

typeset -gA keysyms

function zle::utils::register_keysym
{
  local sym="$1"
  local prefered_val="$2"
  local fallback_val="$3" # may be empty

  if [[ -n "$prefered_val" ]]; then
    keysyms[$sym]="$prefered_val"
  else
    keysyms[$sym]="$fallback_val"
  fi
}

# Define keysyms for main non-letter keys.
# Few rules:
# - Prefer using the sequence from terminfo first, if terminfo spec has an entry for it.
# - Always add a fallback if the first value may be empty (e.g: `terminfo` var can be
#   empty when terminfo is not available)

zle::utils::register_keysym Home "${terminfo[khome]}" "[1~"
zle::utils::register_keysym End  "${terminfo[kend]}"  "[4~"

zle::utils::register_keysym Insert "${terminfo[kich1]}" "[2~"
zle::utils::register_keysym Delete "${terminfo[kdch1]}" "[3~"
zle::utils::register_keysym PageUp "${terminfo[kpp]}" "[5~"
zle::utils::register_keysym PageDown "${terminfo[knp]}" "[6~"

zle::utils::register_keysym Left "${terminfo[kcub1]}" "[D"
zle::utils::register_keysym Down "${terminfo[kcud1]}" "[B"
zle::utils::register_keysym Up "${terminfo[kcuu1]}" "[A"
zle::utils::register_keysym Right "${terminfo[kcuf1]}" "[C"

# The backspace key is usually ^? but can be ^h on some terminal.
# NOTE: None of my installed ones (xterm, urxvt, termite, konsole, kitty, wezterm) uses ^h
# so it's pretty unusual anyway (maybe on macos?).
# It would be great to simply read the sequence defined in terminfo,
# unfortunately the value may be wrong:
# For example the xterm-256color terminfo says that Backspace is ^h, but in practice
# xterm always sends ^? (in normal mode & application mode).
#
# That's why we default to ^? by default unless the following env var is set..
if [[ -n "$_ZLE_MAP_BACKSPACE_FROM_TERMINFO" ]]; then
  # Note: Backspace can be ^h on some terminal
  zle::utils::register_keysym Backspace "${terminfo[kbs]}" "^?"
else
  zle::utils::register_keysym Backspace "^?"
fi

zle::utils::register_keysym Tab   "^I"
zle::utils::register_keysym S-Tab "${terminfo[kcbt]}" "^I" # on linux console: S-Tab == M-Tab

zle::utils::register_keysym Enter "^M"

#-------------------------------------------------------------

# Allows to have fast switch Insert => Normal, but still be able to
# use multi-key bindings in normal mode (e.g. surround's 'ys' 'cs' 'ds')
#
# NOTE: default is KEYTIMEOUT=40
function zle::utils::setup_keytimeout_per_keymap
{
  zle::utils::get-vim-mode
  case "$REPLY" in
    insert) KEYTIMEOUT=1;; # 10ms
    *) KEYTIMEOUT=100;; # 1000ms | 1s
  esac

  # zle -M "KEYTIMEOUT = $KEYTIMEOUT" # debug..
}
hooks-add-hook zle_keymap_select_hook zle::utils::setup_keytimeout_per_keymap
hooks-add-hook zle_line_init_hook zle::utils::setup_keytimeout_per_keymap

function vibindkey
{
  bindkey -M viins "$@"
  bindkey -M vicmd "$@"
}
compdef _bindkey vibindkey

# TODO: better binds organization

bindkey -M viins "${keysyms[Tab]}" menu-complete
bindkey -M viins "${keysyms[S-Tab]}" reverse-menu-complete
bindkey -M viins "^n" menu-complete

bindkey -M viins ":" execute-named-cmd

vibindkey '^l' zwidget::clear-but-keep-scrollback

vibindkey 's' zwidget::toggle-sudo-nosudo

vibindkey 'q' zwidget::cycle-quoting
vibindkey '^a' zwidget::insert_one_arg

# Alt-Enter => insert a newline
vibindkey "${keysyms[Enter]}" self-insert-unmeta

# Ctrl-Alt-L => force scroll window for free thinking :)
vibindkey '^l' zwidget::force-scroll-window

# fast git
vibindkey 'g' zwidget::git-status
vibindkey 'd' zwidget::git-diff
vibindkey 'D' zwidget::git-diff-cached
#vibindkey 'l' zwidget::git-log # handled by zwidget::go-right_or_git-log
vibindkey 'L' zwidget::git-log-always-for-repo

# Ctrl-Alt-E => edit line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
vibindkey '^e' edit-command-line

source $ZSH_MY_CONF_DIR/rc/fzf-mappings.zsh
vibindkey 'f' zwidget::fzf::smart_find_file
vibindkey 'F' zwidget::fzf::find_file
vibindkey 'c' zwidget::fzf::find_directory
vibindkey 'z' zwidget::fzf::z
bindkey -M vicmd '/' zwidget::fzf::history
bindkey -M viins '/' zwidget::fzf::history
vibindkey 'a' zwidget::fzf::git_changed_files_in_cwd
vibindkey 'A' zwidget::fzf::git_changed_files # all
# IDEA: use ^f as a key prefix for more fuzzy search actions? (^x^f is used for builtin file search)

# Ctrl-Z => fg %+
vibindkey '^z' zwidget::fg
# Ctrl-Alt-Z => fg %-
vibindkey '^z' zwidget::fg2


# Fix keybinds when returning from command mode
# FIXME: WHY DID THIS STOPPED WORKING????
# => I've found the problem.... ^? (Backspace) is bound to autopair-delete...
#    which might not work correctly w.r.t zsh's vim mode and the back-to-insert behavior..
# Digging more...:
# * When zsh starts, it sets keybind's vi mode if it finds 'vi' in $VISUAL or $EDITOR
# * The autopair plugin saves the current Backspace widget when the plugin is
#   initially sourced (and before my own keybinds are set)
#   (See: https://github.com/hlissner/zsh-autopair/blob/9876030c97ee2c292e409030049c6c6d444eb185/autopair.zsh#L6)
#   => The saved keybind is vi-backward-delete-char, which does NOT work after
#      insert-normal-insert dance.
# * And found an old open issue (tagged 'help wanted') on autopair-zsh:
#    https://github.com/hlissner/zsh-autopair/issues/14 (-> MAYBE I CAN FIX IT?)
#
# Few solutions:
# 1. Fix the vi-* widgets (alias them to what I want) instead of fixing the keys
#    individually.
# 2. Fix autopair-zsh plugin, by (I think?) saving the keys on autopair-init call,
#    not when sourcing the plugin.
# 3. Set AUTOPAIR_BKSPC_WIDGET="backward-delete-char" before sourcing the plugin.
# 4. Move plugin loading AFTER my config (options, mappings, prompt, ...)
bindkey "${keysyms[Backspace]}" backward-delete-char # Backspace
AUTOPAIR_BKSPC_WIDGET="backward-delete-char" # tmp, see big comment above

bindkey '^w' backward-kill-word
bindkey '^u' backward-kill-line

# Delete backward until a path separator
function backward-kill-partial-path
{
  # Remove '/' from being a part of a word
  local WORDCHARS="${WORDCHARS:s#/#}"
  zle backward-kill-word
}
zle -N backward-kill-partial-path

bindkey "${keysyms[Backspace]}" backward-kill-partial-path # Alt-Backspace

function toggle-replace-mode
{
  if [[ $ZLE_STATE == *overwrite* ]]; then
    zle vi-insert
  else
    zle vi-replace
  fi
  zle::utils::reset-prompt
}
zle -N toggle-replace-mode

bindkey -M vicmd "${keysyms[Insert]}" vi-replace
bindkey "${keysyms[Insert]}" toggle-replace-mode

# Sane default
bindkey "${keysyms[Delete]}" delete-char
bindkey -M vicmd "${keysyms[Delete]}" zwidget::noop

vibindkey "${keysyms[Home]}" beginning-of-line
vibindkey "${keysyms[End]}" end-of-line

vibindkey "${keysyms[PageUp]}" beginning-of-buffer-or-history # like gg in vicmd
vibindkey "${keysyms[PageDown]}" vi-fetch-history             # like G in vicmd

# Cut the buffer and push it on the buffer stack
function push-input-go-insert-mode
{
  zle push-input
  zle vi-insert
}
zle -N push-input-go-insert-mode

bindkey -M vicmd '#' push-input-go-insert-mode
bindkey -M viins '#' push-input

# Mimic the vim-surround plugin
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround

# Logical redo (u U)
bindkey -M vicmd 'U' redo

# START OF COPY/PASTE SETUP

function zwidget::clipboard-visual-paste
{
  local content=$(cli-clipboard-provider paste-from smart-session)
  zle copy-region-as-kill "$content" # copy content in the kill buffer
  zle put-replace-selection
}
zle -N zwidget::clipboard-visual-paste

function zwidget::clipboard-paste-before
{
  CUTBUFFER=$(cli-clipboard-provider paste-from smart-session)
  zle vi-put-before
}
zle -N zwidget::clipboard-paste-before

function zwidget::clipboard-paste-after
{
  CUTBUFFER=$(cli-clipboard-provider paste-from smart-session)
  zle vi-put-after
}
zle -N zwidget::clipboard-paste-after

function zwidget::clipboard-visual-copy
{
  zle vi-yank # copy region to kill buffer
  local content="$CUTBUFFER"
  printf "%s" "$content" | cli-clipboard-provider copy-to smart-session
  zle -M "Copied to session clipboard!"
}
zle -N zwidget::clipboard-visual-copy

# Copy/paste in the session (or system as fallback)
bindkey -M visual 'c' zwidget::clipboard-visual-copy
bindkey -M visual 'v' zwidget::clipboard-visual-paste
bindkey -M viins 'v' zwidget::clipboard-paste-before
bindkey -M vicmd 'v' zwidget::clipboard-paste-after

# copy selection to host system (via osc52)
function zwidget::clipboard-visual-copy-to-system
{
  zle vi-yank # copy region to kill buffer
  local content="$CUTBUFFER"
  export CLIPBOARD_REQUESTOR_TTY=$TTY # needed for osc52 (see its provider for details)
  printf "%s" "$content" | cli-clipboard-provider copy-to system
  zle -M "Copied to system clipboard! ('$content')"
}
zle -N zwidget::clipboard-visual-copy-to-system

bindkey -M visual 'C' zwidget::clipboard-visual-copy-to-system

# END OF COPY/PASTE SETUP

# - Go right if possible (if there is text on the right)
# - Call `git log` if no text on the right (or empty input line)
function zwidget::go-right_or_git-log
{
  if [[ -z "$RBUFFER" ]]; then
    zwidget::git-log
  else
    zle forward-char
  fi
}
zle -N zwidget::go-right_or_git-log

# When in zsh-vim normal mode, the cursor is never after the last char, we must ignore it
function zwidget::go-right_or_git-log::vicmd
{
  if [[ ${#RBUFFER} == 1 ]] || [[ -z $BUFFER ]]; then
    # cursor on last char, or empty buffer
    zwidget::git-log
  else
    zle forward-char
  fi
}
zle -N zwidget::go-right_or_git-log::vicmd

# Alt-h/l to move left/right in insert mode
bindkey -M viins 'h' backward-char
bindkey -M viins 'l' zwidget::go-right_or_git-log # + git log

bindkey -M vicmd 'l' zwidget::go-right_or_git-log::vicmd # fix git log in normal mode
# Alt-j/k are the same as: Esc then j/k
# Doing Esc-j/k will go to normal mode, then go down/up
#
# Why: it's almost never useful to go up/down, while staying in insert mode

vibindkey 'b' zwidget::jump-previous-shell-arg
vibindkey 'e' zwidget::jump-end-shell-arg
vibindkey 'w' zwidget::jump-next-shell-arg
vibindkey '^' beginning-of-line
vibindkey '$' end-of-line

# Alt-u/U to undo/redo (from anywhere)
vibindkey 'u' undo
vibindkey 'U' redo

# Ctrl-a to increment number under the cursor
autoload -Uz incarg
zle -N incarg
bindkey -M vicmd '^a' incarg

# Use Up/Down to get history with current cmd prefix..
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
bindkey "${keysyms[Up]}" up-line-or-beginning-search
bindkey "${keysyms[Down]}" down-line-or-beginning-search


# Vi OPerator Pending keybindings (text objects)
#-------------------------------------------------------------

# Add many text objects like: a' i' a) i( a} i_ a/ i`
# From https://thevaluable.dev/zsh-line-editor-configuration-mouseless/
autoload -Uz select-bracketed select-quoted
zle -N select-quoted; zle -N select-bracketed

for keymap in viopp visual; do
  # NOTE: {a,i}${(s..)^:-hjkl} would generate the list: ah ih aj ij ak ik al il
  # (I don't understand everything, like what '^:-' is for.. but it's necessary syntax)
  for c in {a,i}${(s..)^:-\'\"\`\|\\,./:;=+@&'!'§%_~}; do
    bindkey -M $keymap -- $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>'}; do
    bindkey -M $keymap -- $c select-bracketed
  done
done

# TODO? A text object to select the entire current command


# menuselect keybindings
#-------------------------------------------------------------

# Ensure Backspace is mapped to 'backward-delete-char',
# necessary for the interactive & search modes.
bindkey -M menuselect "${keysyms[Backspace]}" backward-delete-char
bindkey -M menuselect "^h" backward-delete-char # to avoid mistakes..

# Cancel the whole current completion
bindkey -M menuselect "" send-break

# TODO: I want to quit while keeping current inserted completions, WITHOUT
#       inserting highlighted entry. (hitting 'space' does insert it)
#
# => Alternative is to do 'accept-line && undo' (accept entry then remove last accepted match)
#    (which cannot be mapped to a user-defined widget, they seems to be disabled in the menu..)
# TODO (feature req): accept user-defined zle widget in the menu

# Alt-Space => cancel current selection
# NOTE: Text entered in interactive mode is retained
# => It's the only sensible way to complete single dash options (like -XY), because otherwise
#    doing - then TAB, then entering the option I want in interactive menu make it disappear
#    from the menu and pressing Space would insert the currently highlighted option, in
#    addition to the one I wanted ><..
bindkey -M menuselect " " send-break # (note: would be nice to add Space after exiting the menu..)
vibindkey -s " " " " # Alt-Space => send Space (makes it easy to use Alt-Space to exit menu, then again to add space)

# FIXME: When menuselect is in interactive mode and has filtering text,
#        it should remove everything in that mode, else, send-break
# TODO (feature req): Add ability to use 'backward-kill-line' when interactive/search mode enabled
#   (and an alternative like 'backward-kill-line-or-break' to 'send-break' in normal menu?)
bindkey -M menuselect "^u" send-break

# Undo last accepted completion
bindkey -M menuselect "^w" undo
bindkey -M menuselect "u" undo

# Accept the current entry, and continue to show the completion list
bindkey -M menuselect "^a" accept-and-hold
bindkey -M menuselect "a" accept-and-hold

# Alt-Enter => Accepts the current match and immediately start a new menu completion.
# >> This allows to select (e.g) a directory and immediately attempt to complete files in it!
#
# NOTE: When in interactive menu mode, this action needs to be executed twice:
#       first to exit interactive mode, second to do the action.
# TODO (feature req): Ability to do the action in interactive menu mode, and keep it enabled!
#   => So I don't have to manually re-enable interactive mode (with vi-insert action) to
#      continue filtering in interactive menu mode.
bindkey -M menuselect "${keysyms[Enter]}" accept-and-infer-next-history

# Toggles between usual and interactive mode <3
# In interactive mode, keys filter the selection without stopping menu completion
bindkey -M menuselect "i" vi-insert
# TODO (bug report): run 'echo 111', then do '!!:' then enter interactive menu mode
#   and type 's:1:2'
#   => the history substitution should NOT happen in interactive mode (??)

# Enables incremental search (not fuzzy) by an arbitrary text <3
# -> Matches anywhere in the menu completions
#    (even in the description of some matches, like commit messages <3)
# FIXME(?): I want to enable smart case matching (lowercase -> uppercase)
#
# => NOTE: In this mode, ONLY >> 'accept-line' << can be used to quit the
#    incremental mode.
#    Usual action keys do not work and will stop/cancel the menu completion.
bindkey -M menuselect "s"  history-incremental-search-forward
bindkey -M menuselect "f"  history-incremental-search-forward
bindkey -M menuselect "^f"   history-incremental-search-forward

# -- Movement keys in the completion menu

# TODO (bug report): When interactive mode is on, the action
#   'menu-complete' (TAB by default) does NOT move to the next match...
#   => This is annoying when interactive mode is enabled by default (via zstyle)
#
#   MAYBE RELATED: When interactive mode is on, 'accept-and-infer-next-history'
#   is not immediate, I need to do it twice: first will exit interactive mode,
#   and second will do the action.
bindkey -M menuselect "${keysyms[Tab]}" forward-char # alternative, but does not cycle well
bindkey -M menuselect "${keysyms[S-Tab]}" reverse-menu-complete
bindkey -M menuselect "^n" down-line-or-history
bindkey -M menuselect "^p" up-line-or-history
# TODO (feature req): Have an action to cycle in the current completion group only.
#   (and bind TAB to it)

# Alt-hjkl to move in complete menu
bindkey -M menuselect "h" backward-char
bindkey -M menuselect "j" down-line-or-history
bindkey -M menuselect "k" up-line-or-history
bindkey -M menuselect "l" forward-char

# Alt-$/0 => go to first/last results on current line
bindkey -M menuselect "0" beginning-of-line
bindkey -M menuselect "$" end-of-line

# Ctrl-Alt-j/k (or (Alt-){/}) => Go to next/previous match group
bindkey -M menuselect "^k" vi-backward-blank-word
bindkey -M menuselect "^j" vi-forward-blank-word
bindkey -M menuselect "{" vi-backward-blank-word
bindkey -M menuselect "}" vi-forward-blank-word
# Also with {/}, should not conflict with a use-case as adding { } during
# a completion is very unlikely to happen.
bindkey -M menuselect "{" vi-backward-blank-word
bindkey -M menuselect "}" vi-forward-blank-word

# Alt-J/K or PageDown/PageUp => Move page by page (wrapping at top/bottom.. :/)
bindkey -M menuselect "K" backward-word
bindkey -M menuselect "J" forward-word
bindkey -M menuselect "${keysyms[PageUp]}"   backward-word
bindkey -M menuselect "${keysyms[PageDown]}" forward-word

# Alt-g/G or Home/End => Go to first/last line (of all lines of matches)
bindkey -M menuselect "g" beginning-of-history
bindkey -M menuselect "G" end-of-history
bindkey -M menuselect "${keysyms[Home]}" beginning-of-history
bindkey -M menuselect "${keysyms[End]}"  end-of-history
