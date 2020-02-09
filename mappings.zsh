#----------------------------------------------------------------------------------
# ZLE Widgets
#----------------------------------------------------------------------------------

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
function zle::utils::no-history-run
{
  local cmd="$1"

  zle push-input
  BUFFER=" " # note: skip history with a leading space
  BUFFER+="$cmd"
  zle .accept-line
}

# Toggle sudo at <bol>
function zwidget::toggle-sudo # TODO: refactor to a re-usable function
{
  # Overwriting BUFFER will reset CURSOR to <bol>
  # so we store its original position first
  local saved_cursor=$CURSOR

  if [ "${BUFFER[1, 5]}" = "sudo " ]; then
    BUFFER="${BUFFER[6, ${#BUFFER}]}"
    (( CURSOR = saved_cursor - 5 ))
  else
    BUFFER="sudo $BUFFER"
    (( CURSOR = saved_cursor + 5 ))
  fi
  zle redisplay
}
zle -N zwidget::toggle-sudo

# Git status
function zwidget::git-status
{
  zle::utils::check_git || return

  zle::utils::no-history-run "git status"
}
zle -N zwidget::git-status

# Git log
function zwidget::git-log
{
  zle::utils::check_git || return

  git pretty-log --all --max-count 42 # don't show too much commits to avoid waiting
}
zle -N zwidget::git-log

# Git diff
function zwidget::git-diff
{
  zle::utils::check_git || return

  git d
}
zle -N zwidget::git-diff

# Git diff cached
function zwidget::git-diff-cached
{
  zle::utils::check_git || return

  git dc
}
zle -N zwidget::git-diff-cached

# FG to the most recent ctrl-z'ed process
# fg %+
function zwidget::fg
{
  [ -z "$(jobs)" ] && zle -M "No running jobs" && return

  zle::utils::no-history-run "fg %+"
}
zle -N zwidget::fg

# FG to the 2nd most recent ctrl-z'ed process
# fg %-
function zwidget::fg2
{
  [ -z "$(jobs)" ] && zle -M "No running jobs" && return
  [ "$(jobs | wc -l)" -lt 2 ] && zle -M "Not enough running jobs" && return

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

    if [[ $ZWIDGET_CURRENT_QUOTING_METHOD == none ]]; then
      # current: none
      # next: single quotes
      REPLY="${(qq)${unquoted_arg}}"
      ZWIDGET_CURRENT_QUOTING_METHOD=single
    elif [[ $ZWIDGET_CURRENT_QUOTING_METHOD == single ]]; then
      # current: single quotes
      # next: double quotes
      REPLY="${(qqq)${unquoted_arg}}"
      ZWIDGET_CURRENT_QUOTING_METHOD=double
    elif [[ $ZWIDGET_CURRENT_QUOTING_METHOD == double ]]; then
      # current: double quotes
      # next: no quotes (none)
      REPLY="${(q)${unquoted_arg}}"
      ZWIDGET_CURRENT_QUOTING_METHOD=none
    fi
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

# Jump to beginning of current or previous shell argument
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

  if (( word_idx == 1 )); then
    # CURSOR is on space before first argument
    # move CURSOR before the beginning of space
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

    # move CURSOR to beginning of last space
    (( CURSOR = CURSOR - ${#sh_args[word_idx]} ))
    # move CURSOR to beginning of previous argument
    (( CURSOR = CURSOR - ${#sh_args[word_idx - 1]} ))
    return
  fi

  if (( word_idx % 2 != 0 )); then
    # CURSOR is on a space
    # move CURSOR to beginning of space
    (( CURSOR = CURSOR - char_idx_in_word + 1))
    # move CURSOR to beginning of previous argument
    (( CURSOR = CURSOR - ${#sh_args[word_idx - 1]} ))
    return
  fi

  # Now CURSOR is on an argument

  if (( char_idx_in_word > 1 )); then
    # CURSOR is somewhere on an argument, jump to beginning of it
    (( CURSOR = CURSOR - char_idx_in_word + 1 ))
    return
  fi

  # Now CURSOR is at beginning of an argument

  if (( word_idx == 2 )); then
    # CURSOR is at beginning of first argument (the command), jump before first space
    (( CURSOR = 0 ))
    return
  fi

  # CURSOR is at beginning of an argument, jump to beginning of previous argument

  # move CURSOR to beginning of space before current argument
  (( CURSOR = CURSOR - ${#sh_args[word_idx - 1]}))
  # move CURSOR to beginning of previous argument
  (( CURSOR = CURSOR - ${#sh_args[word_idx - 2]}))
}
zle -N zwidget::jump-previous-shell-arg

# Jump to the end of current or next shell argument
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
function zwidget::jump-next-shell-arg
{
    autoload -U split-shell-arguments

    local reply REPLY REPLY2
    split-shell-arguments
    local word_idx=$REPLY char_idx_in_word=$REPLY2
    local sh_args=("${reply[@]}") # copy $reply array, keeping blank and empty elements

    if (( word_idx == ${#sh_args})); then
        # CURSOR is on space after last argument
        # move CURSOR after the end of the buffer
        (( CURSOR = ${#BUFFER} ))
        return
    fi

  if (( word_idx % 2 != 0 )); then
    # CURSOR is on a space
    # move CURSOR to the end of space
    (( CURSOR = CURSOR + (${#sh_args[word_idx]} - char_idx_in_word) ))
    # move CURSOR to the end of next argument
    (( CURSOR = CURSOR + ${#sh_args[word_idx + 1]} ))
    return
  fi

  # Now CURSOR is on an argument

  if (( char_idx_in_word < ${#sh_args[word_idx]} )); then
    # CURSOR is somewhere on an argument, jump to the end of it
    (( CURSOR = CURSOR + (${#sh_args[word_idx]} - char_idx_in_word) ))
    return
  fi

  # Now CURSOR is at the end of an argument

  if (( word_idx == (${#sh_args} - 1) )); then
    # CURSOR is at the end of last argument, jump after last space (can be empty)
    (( CURSOR = ${#BUFFER} ))
    return
  fi

  # CURSOR is at the end of an argument, jump to the end of the next argument

  # move CURSOR to the end of space after current argument
  (( CURSOR = CURSOR + ${#sh_args[word_idx + 1]}))
  # move CURSOR to the end of next argument
  (( CURSOR = CURSOR + ${#sh_args[word_idx + 2]}))
}
zle -N zwidget::jump-next-shell-arg
#-------------------------------------------------------------
# Mappings

# Enable vim mode
bindkey -v

#-------------------------------------------------------------

# Allows to have fast switch Insert => Normal, but still be able to
# use multi-key bindings in normal mode (e.g. surround's 'ys' 'cs' 'ds')
#
# NOTE: default is KEYTIMEOUT=40
function helper::setup_keytimeout_per_keymap
{
  if [[ "$KEYMAP" =~ (viins|main) ]]; then
    KEYTIMEOUT=1 # 10ms
  else
    KEYTIMEOUT=100 # 1000ms | 1s
  fi
}
hooks-add-hook zle_keymap_select_hook helper::setup_keytimeout_per_keymap

function vibindkey
{
  bindkey -M viins "$@"
  bindkey -M vicmd "$@"
}
compdef _bindkey vibindkey

# TODO: better binds organization

vibindkey 's' zwidget::toggle-sudo

vibindkey 'q' zwidget::cycle-quoting
vibindkey 'a' zwidget::insert_one_arg

# fast git
vibindkey 'g' zwidget::git-status
vibindkey 'd' zwidget::git-diff
vibindkey 'D' zwidget::git-diff-cached
#vibindkey 'l' zwidget::git-log # handled by zwidget::go-right_or_git-log

autoload -U edit-command-line
zle -N edit-command-line

# Alt-E => edit line in $EDITOR
vibindkey 'e' edit-command-line

source ~/.zsh/fzf-mappings.zsh
vibindkey 'f' zwidget::fzf::smart_find_file
vibindkey 'F' zwidget::fzf::find_file
vibindkey 'c' zwidget::fzf::find_directory
vibindkey 'z' zwidget::fzf::z
bindkey -M vicmd '/' zwidget::fzf::history
bindkey -M viins '/' zwidget::fzf::history

# Ctrl-Z => fg %+
vibindkey '^z' zwidget::fg
# Ctrl-Alt-Z => fg %-
vibindkey '^z' zwidget::fg2


# Fix keybinds when returning from command mode
bindkey '^?' backward-delete-char # Backspace
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

bindkey '^h' backward-kill-partial-path # Ctrl-Backspace

# Sane default
bindkey '\e[2~' overwrite-mode # Insert key
bindkey '\e[3~' delete-char # Del (Suppr) key
vibindkey '\e[7~' beginning-of-line # Home key
vibindkey '\e[8~' end-of-line # End key

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
vibindkey 'w' zwidget::jump-next-shell-arg

# Use Up/Down to get history with current cmd prefix..
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
zmodload zsh/terminfo
bindkey $terminfo[kcuu1] up-line-or-beginning-search
bindkey $terminfo[kcud1] down-line-or-beginning-search

# menuselect keybindings
#-------------------------------------------------------------

# enable go back in completions with S-Tab
bindkey -M menuselect '[Z' reverse-menu-complete

# Cancel current completion with Esc
bindkey -M menuselect '' send-break

# Alt-hjkl to move in complete menu
bindkey -M menuselect 'h' backward-char
bindkey -M menuselect 'j' down-line-or-history
bindkey -M menuselect 'k' up-line-or-history
bindkey -M menuselect 'l' forward-char

# Alt-$ & Alt-0 => go to first & last results
bindkey -M menuselect '0' beginning-of-line
bindkey -M menuselect '$' end-of-line

# Alt-J/K => go to next/previous match group
bindkey -M menuselect 'K' vi-backward-blank-word
bindkey -M menuselect 'J' vi-forward-blank-word

# Alt-g & Alt-G => go to first/last line (of all lines of matches)
bindkey -M menuselect 'g' beginning-of-history
bindkey -M menuselect 'G' end-of-history

# Accept the completion entry but continue to show the completion list
bindkey -M menuselect 'a' accept-and-hold
