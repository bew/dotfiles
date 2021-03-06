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

  echo -n $'\e[4S' # Scroll the terminal
  echo -n $'\e[4A' # Move the cursor back up

  zle redisplay
}
zle -N zwidget::force-scroll-window

# When set, git mappings will show status/log/diff for the current directory
# instead of the whole repo.
GIT_MAPPINGS_ARE_FOR_CWD="${GIT_MAPPINGS_ARE_FOR_CWD:-}"

# Git status (for repo or cwd)
function zwidget::git-status
{
  zle::utils::check_git || return

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    zle::utils::no-history-run "git status"
  else
    zle::utils::no-history-run "git status .  # for cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
  fi
}
zle -N zwidget::git-status

# Git log (for repo or cwd)
function zwidget::git-log
{
  zle::utils::check_git || return

  local cmd=(git pretty-log --all --max-count 42) # don't show too much commits to avoid waiting

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    "${cmd[@]}"
  else
    echo # to ensure we're on a new blank line
    echo "!! WARNING: Showing git logs of cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
    "${cmd[@]}" .
  fi

  zle reset-prompt
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
  else
    echo # to ensure we're on a new blank line
    echo "!! WARNING: Showing git diff of cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
    git d .
  fi

  zle reset-prompt
}
zle -N zwidget::git-diff

# Git diff cached (for repo or cwd)
function zwidget::git-diff-cached
{
  zle::utils::check_git || return

  if [[ -z "$GIT_MAPPINGS_ARE_FOR_CWD" ]]; then
    git dc
  else
    echo # to ensure we're on a new blank line
    echo "!! WARNING: Showing git diff of cwd, unset GIT_MAPPINGS_ARE_FOR_CWD for repo"
    git dc .
  fi

  zle reset-prompt
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

function zwidget::noop
{
  # do nothing!
}
zle -N zwidget::noop

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
  hooks-add-hook zle_line_init_hook zle::utils::enable-app-mode
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

  # zle -M "KEYTIMEOUT = $KEYTIMEOUT"
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

source ~/.zsh/rc/fzf-mappings.zsh
vibindkey 'f' zwidget::fzf::smart_find_file
vibindkey 'F' zwidget::fzf::find_file
vibindkey 'c' zwidget::fzf::find_directory
vibindkey 'z' zwidget::fzf::z
bindkey -M vicmd '/' zwidget::fzf::history
bindkey -M viins '/' zwidget::fzf::history
vibindkey 'a' zwidget::fzf::git_changed_files_in_cwd
vibindkey 'A' zwidget::fzf::git_changed_files # all

# Ctrl-Z => fg %+
vibindkey '^z' zwidget::fg
# Ctrl-Alt-Z => fg %-
vibindkey '^z' zwidget::fg2


# Fix keybinds when returning from command mode
bindkey "${keysyms[Backspace]}" backward-delete-char # Backspace
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
vibindkey 'w' zwidget::jump-next-shell-arg

# Use Up/Down to get history with current cmd prefix..
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
bindkey "${keysyms[Up]}" up-line-or-beginning-search
bindkey "${keysyms[Down]}" down-line-or-beginning-search

# menuselect keybindings
#-------------------------------------------------------------

# enable go back in completions with S-Tab
bindkey -M menuselect "${keysyms[S-Tab]}" reverse-menu-complete

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
bindkey -M menuselect ' ' accept-and-hold
