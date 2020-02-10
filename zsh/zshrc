#
#                     oooo                                         .o88o.
#                     `888                                         888 `"
#   oooooooo  .oooo.o  888 .oo.    .ooooo.   .ooooo.  ooo. .oo.   o888oo
#  d'""7d8P  d88(  "8  888P"Y88b  d88' `"Y8 d88' `88b `888P"Y88b   888
#    .d8P'   `"Y88b.   888   888  888       888   888  888   888   888
#  .d8P'  .P o.  )88b  888   888  888   .o8 888   888  888   888   888
# d8888888P  8""888P' o888o o888o `Y8bod8P' `Y8bod8P' o888o o888o o888o
#

# colors for common binaries (ls, tree, etc..)
#
# NOTE: must be done early (not sure why)
if command -v dircolors >/dev/null; then
  DIRCOLORS_FILE=~/.dircolors
  ! [[ -f $DIRCOLORS_FILE ]] && dircolors -p > $DIRCOLORS_FILE
  [[ -f $DIRCOLORS_FILE ]] && eval `dircolors $DIRCOLORS_FILE`
fi

#-------------------------------------------------------------
# Setup Hooks

# better zsh-hooks
source ~/.zsh/third-party/zsh-hooks/zsh-hooks.plugin.zsh

## ZSH HOOKS

# precmd_hook
hooks-define-hook precmd_hook
function precmd-wrapper { hooks-run-hook precmd_hook }
add-zsh-hook precmd precmd-wrapper

# preexec_hook
hooks-define-hook preexec_hook
function preexec-wrapper { hooks-run-hook preexec_hook "$@" }
add-zsh-hook preexec preexec-wrapper

# chpwd_hook
hooks-define-hook chpwd_hook
function chpwd-wrapper { hooks-run-hook chpwd_hook }
add-zsh-hook chpwd chpwd-wrapper

#-------------------------------------------------------------
# Load Plugins

# zplugin
source ~/.zsh/third-party/zplugin/zplugin.zsh

# Syntax highlighting
zplugin light zdharma/fast-syntax-highlighting
# Note: to activate/update my custom theme, run:
#   fast-theme ~/.zsh/fast-theme--bew.ini

# cd with 'frecency' (recent + frequence)
zplugin light rupa/z

# Git branch in prompt (using fast gitstatusd daemon)
zplugin load romkatv/gitstatus
gitstatus_start MY


#-------------------------------------------------------------
# remember recent directories (use with 'cdr')
autoload -Uz cdr

# The original chpwd_recent_dirs (from autoload) doesn't work when the
# chpwd hook is called after a non-toplevel `cd`, e.g when we `cd` from a script
# or a function.
#
# This chpwd_recent_dirs adds a way to force the hook to run, when $HOOK_LIKE_TOPLEVEL
# is defined.
#
# It allows you to write:
#
#   HOOK_LIKE_TOPLEVEL=1 hooks-run-hook chpwd_hook
#
# to run the hooks related to chpwd_hook, forcing their execution (at least for
# chpwd_recent_dirs).
function chpwd_recent_dirs
{
    emulate -L zsh
    setopt extendedglob
    local -aU reply
    integer changed
    autoload -Uz chpwd_recent_filehandler chpwd_recent_add

    # BEGIN ADDITION
    local is_toplevel_or_forced=1
    if [[ -n $ZSH_EVAL_CONTEXT && $ZSH_EVAL_CONTEXT != toplevel(:[a-z]#func|)# ]]; then
        # not called from toplevel (=> script)
        is_toplevel_or_forced=0
        if [[ -n "$HOOK_LIKE_TOPLEVEL" ]]; then
            is_toplevel_or_forced=1
        fi
    fi

    [[ $is_toplevel_or_forced == 0 ]] && return
    # END ADDITION

    if [[ ! -o interactive || $ZSH_SUBSHELL -ne 0 ]]; then
        return
    fi
    chpwd_recent_filehandler
    if [[ $reply[1] != $PWD ]]; then
        chpwd_recent_add $PWD && changed=1
        (( changed )) && chpwd_recent_filehandler $reply
    fi
}
hooks-add-hook chpwd_hook chpwd_recent_dirs

#-------------------------------------------------------------
# Options
source ~/.zsh/rc/options.zsh

#-------------------------------------------------------------
# Completion
source ~/.zsh/rc/completions.zsh

#-------------------------------------------------------------
# Bracketed paste that handles URL & Undo

# Override the default `bracketed-paste` widget, triggered when an external paste
# is incoming to the shell.

autoload -Uz bracketed-paste-url-magic

function my-bracketed-paste-with-undo
{
  # Add an undo mark before receiving the pasted-content, so that the paste can
  # be easily undo-able without loosing anything I might have written before.
  zle split-undo

  # Use bracketed-paste-url-magic that does what bracketed-paste does but also
  # quotes the paste if it looks like a URL.
  bracketed-paste-url-magic
}
zle -N bracketed-paste my-bracketed-paste-with-undo


#-------------------------------------------------------------
# Aliases
source ~/.zsh/rc/aliases_and_short_funcs.zsh

#-------------------------------------------------------------
# Prompt
source ~/.zsh/rc/prompt.zsh

#-------------------------------------------------------------
# Keybinds
source ~/.zsh/rc/mappings.zsh

#-------------------------------------------------------------
# Terminal title
source ~/.zsh/rc/terminal_title.zsh

#-------------------------------------------------------------
# SSH Agent handling
source ~/.zsh/rc/ssh_agent.zsh


#-------------------------------------------------------------
# Functions

fpath=(~/.zsh/fpath $fpath)

autoload -U repeat_every_while
alias repeat_while="repeat_every_while 1"

autoload -U myip
autoload -U weather

autoload -U countdown chronometer

autoload -U transfer

autoload -U http::serve-local

autoload -U extract
alias extract::dry-run='extract --dry-run'

# Switch terminal colors dark/light at runtime
function switch-term-colors
{
  local color_mode=$(command switch-term-colors "$@")
  if [[ "$color_mode" =~ "Usage" ]]; then
    echo "$color_mode" # print error
    return 1
  else
    export TERM_COLOR_MODE="$color_mode"
  fi
}

# ------------------------------------------------------------
# Media helper funcs

autoload -U watch_and_seen
compdef _mpv watch_and_seen

autoload -U ffmpeg::load_funcs

autoload -U mpv::load_funcs
alias tv-start='mpv::start-daemon tv --no-terminal --force-window'
alias tv-add='mpv::add-media tv'

#-------------------------------------------------------------
# MISC - not sure where to put these...

# Import zsh's massive rename helper
autoload -U zmv
alias zmv='noglob zmv'
alias zcp='zmv -C'
alias zln='zmv -L'
alias zmv::dry-run='zmv -n'
alias zcp::dry-run='zcp -n'
alias zln::dry-run='zln -n'


#-------------------------------------------------------------
# Load local per-machine zsh config

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

true # The config should always finish well!
