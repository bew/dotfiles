#
#  ::::::::: ::::::::  :::    :::       ::::::::   ::::::::  ::::    ::: ::::::::::
#       :+: :+:    :+: :+:    :+:      :+:    :+: :+:    :+: :+:+:   :+: :+:
#      +:+  +:+        +:+    +:+      +:+        +:+    +:+ :+:+:+  +:+ +:+
#     +#+   +#++:++#++ +#++:++#++      +#+        +#+    +:+ +#+ +:+ +#+ :#::+::#
#    +#+           +#+ +#+    +#+      +#+        +#+    +#+ +#+  +#+#+# +#+
#   #+#     #+#    #+# #+#    #+#      #+#    #+# #+#    #+# #+#   #+#+# #+#
#  ######### ########  ###    ###       ########   ########  ###    #### ###
#
#

# Import color helpers
autoload -U colors && colors

# colors for common binaries (ls, tree, etc..)
DIRCOLORS_FILE=~/.dircolors
! [ -f $DIRCOLORS_FILE ] && dircolors -p > $DIRCOLORS_FILE
[ -f $DIRCOLORS_FILE ] && eval `dircolors $DIRCOLORS_FILE`

#----------------------------------------------------------------------------------
# Setup Hooks
#----------------------------------------------------------------------------------

# better zsh-hooks
source ~/.zsh/zsh-hooks/zsh-hooks.plugin.zsh

## ZSH HOOKS

# precmd_hook
hooks-define-hook precmd_hook
function precmd-wrapper { hooks-run-hook precmd_hook }
add-zsh-hook precmd precmd-wrapper

# preexec_hook
hooks-define-hook preexec_hook
function preexec-wrapper { hooks-run-hook preexec_hook $@ }
add-zsh-hook preexec preexec-wrapper

# chpwd_hook
hooks-define-hook chpwd_hook
function chpwd-wrapper { hooks-run-hook chpwd_hook }
add-zsh-hook chpwd chpwd-wrapper

# CUSTOM HOOKS
#-------------------------------------------------------------

hooks-define-hook pre_accept_line_hook

#----------------------------------------------------------------------------------
# Load Plugins
#----------------------------------------------------------------------------------

# cd with 'frecency' (recent + frequence)
#-------------------------------------------------------------
source ~/.zsh/z/z.sh

# Syntax hightlighting
#-------------------------------------------------------------
# Sourcing happens at end of zshrc (more info at eof)

ZSH_HIGHLIGHT_HIGHLIGHTERS=(
  main # the base highlighter, and the only one active by default.
  brackets # matches brackets and parenthesis.
  #pattern # matches user-defined patterns.
  #cursor # matches the cursor position.
  #root # highlights the whole command line if the current user is root.
  #line # applied to the whole command line.
)

typeset -A ZSH_HIGHLIGHT_STYLES

# main highlighter config:
#----------------------------------------

# ┌─ unknown tokens / errors
ZSH_HIGHLIGHT_STYLES[unknown-token]='bg=red,bold'
# ┌─ shell reserved words (if, for)
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=208,bold' # orange
# ┌─ aliases
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
# ┌─ suffix aliases (requires zsh 5.1.1 or newer)
ZSH_HIGHLIGHT_STYLES[suffix-alias]= # unset
# ┌─ shell builtin commands (shift, pwd, zstyle)
ZSH_HIGHLIGHT_STYLES[builtin]='fg=208' # orange
# ┌─ function names
ZSH_HIGHLIGHT_STYLES[function]='fg=cyan'
# ┌─ command names
ZSH_HIGHLIGHT_STYLES[command]='fg=blue,bold'
# ┌─ precommand modifiers (e.g., noglob, builtin)
ZSH_HIGHLIGHT_STYLES[precommand]='fg=white,underline'
# ┌─ command separation tokens (;, &&)
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=208' # orange
# ┌─ hashed commands
ZSH_HIGHLIGHT_STYLES[hashed-command]= # unset
# ┌─ existing filenames
ZSH_HIGHLIGHT_STYLES[path]='fg=yellow'
# ┌─ path separators in filenames (/); if unset, path is used (default)
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=202' # cool red
# ┌─ prefixes of existing filenames
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=172' # yellow dark
# ┌─ path separators in prefixes of existing filenames (/); if unset, path_prefix is used (default)
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=202' # cool red
# ┌─ globbing expressions (*.txt)
ZSH_HIGHLIGHT_STYLES[globbing]='fg=cyan'
# ┌─ history expansion expressions (!foo and ^foo^bar)
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=white,underline'
# ┌─ single-hyphen options (-o)
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=green'
# ┌─ double-hyphen options (--option)
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=green'
# ┌─ backtick command substitution (`foo`)
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=blue'
# ┌─ unclosed backtick command substitution (`foo)
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=blue,underline'
# ┌─ single-quoted arguments ('foo')
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=cyan'
# ┌─ unclosed single-quoted arguments ('foo)
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=cyan,underline'
# ┌─ double-quoted arguments ("foo")
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=cyan'
# ┌─ unclosed double-quoted arguments ("foo)
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=cyan,underline'
# ┌─ dollar-quoted arguments ($'foo')
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]= # unset
# ┌─ unclosed dollar-quoted arguments ($'foo)
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]= # unset
# ┌─ two single quotes inside single quotes when the RC_QUOTES option is set ('foo''bar')
ZSH_HIGHLIGHT_STYLES[rc-quote]= # unset
# ┌─ parameter expansion inside double quotes ($foo inside "")
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=cyan'
# ┌─ backslash escape sequences inside double-quoted arguments (\" in "foo\"bar")
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=cyan'
# ┌─ backslash escape sequences inside dollar-quoted arguments (\x in $'\x48')
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]= # unset
# ┌─ parameter assignments (x=foo and x=( ))
ZSH_HIGHLIGHT_STYLES[assign]= # unset
# ┌─ redirection operators (<, >, etc)
ZSH_HIGHLIGHT_STYLES[redirection]= # unset
# ┌─ comments, when setopt INTERACTIVE_COMMENTS is in effect (echo # foo)
ZSH_HIGHLIGHT_STYLES[comment]= # unset
# ┌─ a command word other than one of those enumrated above (other than a command, precommand, alias, function, or shell builtin command).
ZSH_HIGHLIGHT_STYLES[arg0]= # unset
# ┌─ everything else
ZSH_HIGHLIGHT_STYLES[default]='none'

# brackets highlighter config:
#----------------------------------------

# ┌─ unmatched brackets
ZSH_HIGHLIGHT_STYLES[bracket-error]='bg=red'
# ┌─ brackets with nest level N
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=magenta,bold'
# ┌─ the matching bracket, if cursor is on a bracket
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='standout'


# Git branch in prompt
#-------------------------------------------------------------

source ~/.zsh/bin/git-prompt.sh # for __git_ps1

# Show if there are unstaged (with *) and/or staged (with +) files
GIT_PS1_SHOWDIRTYSTATE=1

# Show if there are untracked (with %) files
GIT_PS1_SHOWUNTRACKEDFILES=1


# remember recent directories (use with 'cdr')
#-------------------------------------------------------------
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



#----------------------------------------------------------------------------------
# UTILS
#----------------------------------------------------------------------------------

# Get the cursor position on the terminal.
#
# It saves the result in CURSOR_POS_ROW & CURSOR_POS_COL
#-------------------------------------------------------------
# FIXME: if the read buffer is not empty, need to discard it
#-------------------------------------------------------------
function term::get_cursor_pos
{
    echo -en "\e[6n"; read -u0 -sd'[' _; read -u0 -sdR pos

    # pos has format 'row;col'
    CURSOR_POS_ROW=${pos%;*} # remove ';col'
    CURSOR_POS_COL=${pos#*;} # remove 'row;'
}

# Sets the status line (title bar for most terminal emulator)
function term::set_status_line
{
    local text="$1"

    # tsl (to_status_line): Move cursor to status line
    # fsl (from_status_line): Move cursor from status line
    if [[ -n "$terminfo[tsl]" ]] && [[ -n "$terminfo[fsl]" ]]; then
        echoti tsl # to status line
        print -Pn "$text"
        echoti fsl # from status line
    fi
}

#----------------------------------------------------------------------------------
# Options
#----------------------------------------------------------------------------------

# do not beep !!!!
unsetopt BEEP

# do not remove slash on directory completion
unsetopt AUTO_REMOVE_SLASH

# enable Completion in the middle of a word
setopt COMPLETE_IN_WORD

# after a middle word completion, move cursor at end of word
setopt ALWAYS_TO_END

# Allow comment (with '#') in zsh interactive mode
setopt INTERACTIVE_COMMENTS

# Allow substitution in the prompt
setopt PROMPT_SUBST

# History options
#-------------------------------------------------------------

HISTFILE=~/.histfile

# Lines of history to keep in memory
HISTSIZE=10000

# Lines to keep in the history file
SAVEHIST=1000000

# ignore history duplications
setopt HIST_IGNORE_DUPS

# Even if there are commands inbetween commands that are the same, still only save the last one
setopt HIST_IGNORE_ALL_DUPS

# Ignore commands with a space before
setopt HIST_IGNORE_SPACE

# When searching history don't display results already cycled through twice
setopt HIST_FIND_NO_DUPS

# Remove extra blanks from each command line being added to history
setopt HIST_REDUCE_BLANKS

# Remove duplicated history entries on history save (usually at end of shell session)
setopt HIST_SAVE_NO_DUPS

# OTHERS
#-------------------------------------------------------------

# Report the status of background jobs immediately, rather than waiting until just before printing a prompt
setopt NOTIFY

# List jobs in the long format
setopt LONG_LIST_JOBS

# Don't kill background jobs on logout
#setopt NOHUP

# Allow functions to have local options
setopt LOCAL_OPTIONS

# Allow functions to have local traps
setopt LOCAL_TRAPS



#----------------------------------------------------------------------------------
# Completion
#----------------------------------------------------------------------------------

# Initialize the completion system
autoload -U compinit && compinit
zmodload zsh/complist

# Activate interactive menu completion
zstyle ':completion:*' menu select

# Directories first when completing files
zstyle ':completion:*' list-dirs-first on

# Formatting and messages
# http://www.masterzen.fr/2009/04/19/in-love-with-zsh-part-one/
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format "$fg[yellow]%B--- %d%b"
zstyle ':completion:*:messages' format "$fg[cyan]%B-> %d%b"
zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# sections for man completion
zstyle ':completion:*:manuals'    separate-sections true
zstyle ':completion:*:manuals.*'  insert-sections   true
zstyle ':completion:*:man:*'      menu yes select

# Case insensitive tab-completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# cd/rm/vim will never select the parent directory (e.g.: cd ../<TAB>)
zstyle ':completion:*:(cd|rm|vim):*' ignore-parents parent pwd

# Color completion for some things.
zstyle ':completion:*' list-colors yes
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:original' list-colors "=*=$color[red];$color[bold]"
zstyle ':completion:*:commands' list-colors "=*=$color[green];$color[bold]"
zstyle ':completion:*:builtins' list-colors "=*=$color[cyan];$color[bold]"
zstyle ':completion:*:functions' list-colors "=*=$color[cyan]"
zstyle ':completion:*:parameters' list-colors "=*=$color[red]"
zstyle ':completion:*:aliases' list-colors "=*=$color[cyan];$color[bold]"
zstyle ':completion:*:reserved-words' list-colors "=*=$color[magenta]"

zstyle ':completion:*:options' list-colors "=^(-- *)=$color[green]"

zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'

# Ignore some files when completing a text editor command
#----------------------------------------

zstyle ":completion:*:*:${EDITOR}:*:*files" ignored-patterns '*.pdf|*.o'

#----------------------------------------------------------------------------------
# Aliases
#----------------------------------------------------------------------------------

function reload_zsh
{
    if [ -n "$(jobs)" ]; then
        echo "Error: $(jobs | wc -l) job(s) in background"
    else
        exec zsh
    fi
}

alias zshrc=reload_zsh

# global aliases

alias -g nostdout=" >/dev/null "
alias -g nostderr=" 2>/dev/null "

# Shorters

alias g=git
alias m=make
alias dk=docker
alias cr=crystal
alias pac=pacman
alias wpa=wpa_cli
alias tre=tree
alias py=python
alias ipy=ipython

alias j=jobs

alias com=command

# Big-one letter aliases

alias A="ack"
alias H="head"
alias T="tail"
alias L="less"
alias V="vim"

alias G="command grep --color=auto -n"

# add verbosity

alias rm="rm -vI"
alias cp="cp -vi"
alias mv="mv -vi"
alias mkdir="mkdir -v"

# ls

alias ls="ls --color=auto --group-directories-first"
alias ll="ls -lh"
alias la='ll -a'
alias l="la"
alias ls1="ls -1"

# misc

alias todo="ack -i 'todo|fixme'"

# ping

alias pingonce="ping -c 1"
alias pg="ping google.fr"

# mkdir

alias mkd="mkdir -p"

# Creates 1 or more directories, then cd into the first one
function mkcd
{
    mkd $*
    cd $1
}

# for emacs users :p
alias ne="echo 'Use: vim'"

# tree

alias tree="tree --dirsfirst -F"

# cd

alias ..='cd ..;'
alias ...='cd ../..;'
alias ....='cd ../../..;'

alias cdt='cd /tmp;'

# pacman


alias pac::list_useless_deps='pacman -Qtdq'

function pac::show_useless_deps
{
    for package in $(pac::list_useless_deps); do
        echo "Package: $package"
        pacman -Qi $package | ack 'Description'
        echo
    done
}

alias pac::remove_useless_deps='command sudo pacman -Rsv $(pac::list_useless_deps)'


# git

alias gnp='git --no-pager'
alias git::status_in_all_repos='find -name .git -prune -print -execdir git status \;'

# sudo

# Makes sudo work with alias (e.g. 'sudo pac' => 'sudo pacman')
# Note: the trailing space is important (see the man for the alias builtin)
alias sudo="sudo "

# Close the current sudo session if any
alias nosudo="sudo -k;"


# original vim
alias ovim="command vim -X"

# nvim

alias vim=nvim
alias v="vim"
alias im="v"
alias vm="v"
alias vi="v"
alias vmi="v"
alias imv="v"
alias ivm="v"

alias ":q"="exit"

# man in vim
function man
{
    /usr/bin/man $* | col -bp | vim -R -c "set ft=man" -
}
compdef _man man


# youtube-dl

alias ytdl='youtube-dl'
alias ytdl-m4a='ytdl --extract-audio -f m4a --ignore-errors'
alias ytdl-m4a-nolist='ytdl-m4a --no-playlist'

# mpv

alias mpv-audio='mpv --no-video'

# clock in terminal

alias clock='tty-clock -sc -C6 -d 0.5'
alias c=clock

# text translation (with https://github.com/soimort/translate-shell)

# translation
alias fr:en='trans fr:en -b'
alias en:fr='trans en:fr -b'

# definition
alias en:def='trans en: -d'
alias fr:def='trans fr: -d'

# misc

alias valgrindleak="valgrind --leak-check=full --show-reachable=yes"
alias cdgit='git rev-parse && cd "$(git rev-parse --show-toplevel)"'

alias makeawesome='make CMAKE_ARGS="-DLUA_LIBRARY=/usr/lib/liblua.so"'

# Hacks

# 'pezop' is a firefox profile, where the browser language is in french, to
# bypass language limitations on www.rotazu.com :)
alias ff_streaming="firefox -P pezop www.rotazu.com &!"


# Fast config edit

alias vimzshrc="vim ~/.zshrc"
alias vimnviminit="vim ~/.config/nvim/init.vim"


# Functions
#----------------------------------------

# Do program multiple times

function repeat_every_while
{
    interval=$1; shift
    cmd=( $* )

    while $cmd; do
        sleep $interval
    done
}

function repeat_while
{
    repeat_every_while 1 $*
}

# Mesure time (arbitrary)

function countdown
{
    local quit
    trap 'echo; quit=1' SIGINT # Prevent lost result on ^C

    local from_seconds=$1
    if [ -z "$from_seconds" ]; then
        from_seconds=60
    fi

    local original_timestamp=$(( `date +%s` + $from_seconds ))

    echo "Counting down from ${from_seconds}s"

    while [ "$original_timestamp" -ge `date +%s` ] && [ -z $quit ]; do
        echo -ne "$(date -u --date @$(( $original_timestamp - `date +%s` )) +%M:%S)\r"
        sleep .1
    done

    date -u --date @$(( $original_timestamp - `date +%s` )) +%M:%S
}

function chronometer
{
    local quit
    trap 'echo; quit=1' SIGINT # Prevent lost result on ^C

    local original_timestamp=`date +%s`

    while [ -z $quit ]; do
        echo -ne "$(date -u --date @$(( `date +%s` - $original_timestamp )) +%M:%S)\r"
        sleep .1
    done

    date -u --date @$(( `date +%s` - $original_timestamp )) +%M:%S
}

# Watch a media with 'mpv' player, then ask to move the media file to 'seen/' directory.
function watch_and_seen
{
    local media_path=$1

    # returns extension length if it is a part file, 0 if it's not
    function length_of_part_extension
    {
        local filepath=$1
        local PART_EXTENSIONS=(.part .crdownload)

        for ext in $PART_EXTENSIONS; do
            pattern=".*$ext"
            if [[ "$filepath" =~ "$pattern" ]]; then
                echo -n ${#ext}
                return
            fi
        done

        echo -n 0 # not a part file
    }
    local part_ext_len=$(length_of_part_extension "$media_path")

    if mpv $*; then
        echo "The player ended successfully"

        if [ ! -f "$media_path" ] && [ $part_ext_len -gt 0 ]; then
            echo "The file '$media_path' doesn't exist anymore, it was a download part file"
            # The file doesn't exist anymore, it was a .part file
            # the final file is without the extension
            local len=${#media_path}
            media_path=${media_path[1, (( len - part_ext_len )) ]} # remove .part
        fi

        # see the man for the "<var>?<prompt>" syntax
        read "reply?Move '$media_path' to 'seen/' ? [y/N] "

        case $reply in
            [Yy])
                mv -i "$media_path" "seen/"
                ;;

            *) # everything (even "") means "no"
                echo "Moving denied."
        esac
    fi
}
compdef _mpv watch_and_seen

# Switch terminal colors dark/light at runtime
function switch-term-colors
{
    local color_mode=$(command switch-term-colors $*)
    export TERM_COLOR_MODE=$color_mode
}

function transfer
{
    if [ $# -eq 0 ]; then
        echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md";
        return 1;
    fi
    tmpfile=$( mktemp -t transferXXX );
    if tty -s; then
        basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g');
        command curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile;
    else
        command curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ;
    fi;
    echo
    command cat $tmpfile;
    command rm -f $tmpfile;
    echo
}


# Named directories
#----------------------------------------

# Now use '~cr/' to access crystal directory
hash -d cr=~/Projects/opensource/crystal
hash -d cr_alt=~/Projects/opensource/crystal_alt

alias ccr='~cr/bin/crystal'

hash -d open=~/Projects/opensource

#----------------------------------------------------------------------------------
# Custom segments (not zle)
#----------------------------------------------------------------------------------

# Segment git branch
function segmt::git_branch
{
    [ -n "$NO_SEGMT_GIT_BRANCH" ] && return

    local branchName=$(__git_ps1 "%s")
    if [ -z "${branchName}" ]; then
        return
    fi
    local branchNameStyle="%{$fg[red]%}${branchName}"

    local gitInfo=" On ${branchNameStyle} "
    local gitInfoStyle="%{$bg[black]%}${gitInfo}%{$reset_color%}"

    echo -n ${gitInfoStyle}
}

# Hook to get the last command exit code
#
# This should be the first hook run after a command, otherwise the exit code won't be correct.
function get-last-exit
{
    LAST_EXIT_CODE=$?
}
hooks-add-hook precmd_hook get-last-exit

# Segment last exit code
function segmt::last_exit_code
{
    if [[ $LAST_EXIT_CODE -ne 0 ]]; then
        local lastExitCode="Last Exit: ${LAST_EXIT_CODE}"
        local lastExitCodeStyle="%{$bg[black]$fg_bold[red]%} ${lastExitCode} %{$reset_color%}"
        echo -n ${lastExitCodeStyle}
    fi
}

# Segment is shell in vim
function segmt::in_vim
{
    if [ -n "$VIM" ]; then
        echo -n " In Vim "
    fi
}

# Segment is shell in sudo session
function segmt::in_sudo
{
    local result=$(sudo -n echo -n bla 2>/dev/null)

    if [ "$result" = "bla" ]; then
        local in_sudo="In sudo"
        local in_sudo_style="%{$bg[red]$fg_bold[white]%} $in_sudo %{$reset_color%}"
        echo -n "$in_sudo_style"
    fi
}

# Segment prompt vim mode (normal/insert)
function segmt::vim_mode
{
    local keymap="$KEYMAP"
    local insert_mode_style="%{$bg[green]$fg_bold[white]%} INSERT %{$reset_color%}"
    local normal_mode_style="%{$bg[blue]$fg_bold[white]%} NORMAL %{$reset_color%}"

    if [ "$keymap" = "vicmd" ]; then
        echo -n ${normal_mode_style}
        return
    fi
    if [[ "$keymap" =~ "(main|viins)" ]]; then
        echo -n ${insert_mode_style}
        return
    fi
    if [ -z "$keymap" ]; then
        echo -n ${insert_mode_style}
        return
    fi

    echo -n "$keymap"
}

function regen-prompt
{
    zle && zle reset-prompt
}
hooks-add-hook zle_keymap_select_hook regen-prompt

zmodload zsh/system

# Scroll when prompt gets too close to bottom edge
function prompt-auto-scroll
{
    # Don't attempt to scroll in a tty
    [ "$TERM" = "linux" ] && return

    # check if there is a command in the stdin buffer
    # (as the term::get_cursor_pos will discard it)
    # FIXME: find how to turn on raw input
    local buff
    sysread -t 0.1 -i 0 buff
    #echo "Buff: '$buff'"
    if [ -n "$buff" ]; then
        # push it on the ZLE input stack
        print -z "${buff}"
    fi

    # Get the cursor position for the (new) current prompt
    term::get_cursor_pos

    if (( CURSOR_POS_ROW > (LINES - 4) )) then
        echo -n $'\e[4S' # Scroll the terminal
        echo -n $'\e[4A' # Move the cursor back up
    fi
}
hooks-add-hook precmd_hook prompt-auto-scroll


function segmt::shlvl
{
    [ $SHLVL = 1 ] && return

    local shlvl='%L'
    local shlvlStyle="%{$fg_bold[red]%}$shlvl  %{$reset_color%}"

    echo -n "${shlvlStyle}"
}

# Segment datetime
function segmt::time
{
    local currentTime=$(date "+%H:%M [%d/%m]")
    local currentTimeStyle=" ${currentTime} "
    echo -n ${currentTimeStyle}
}

# Segment variable debug
function segmt::debug
{
    local debugVar=$*
    local debugVarStyle="%{$bg[blue]%} DEBUG: ${debugVar} %{$bg[default]%}"
    echo ${debugVarStyle}
}


local username='%n'
local usernameStyle="%{$fg[yellow]%}${username}%{$reset_color%}"

local currDir='%2~'
local currDirStyle="%{$fg_bold[cyan]%} ${currDir} %{$reset_color%}"

local cmdSeparator='%%'
local cmdSeparatorStyle="%{$fg_bold[magenta]%}${cmdSeparator}%{$reset_color%}"

## Prompt
##############################################
autoload -U promptinit && promptinit

PROMPT_LINE='$(segmt::shlvl)'" [${usernameStyle}] ${currDir} ▷ "
PROMPT_LINE_OLD='$(segmt::shlvl)'"%{$bg[black]%}${currDirStyle}%{$bg[default]%} ${cmdSeparatorStyle} "




## RPROMPT
##############################################


RPROMPT_LINE='$(segmt::in_vim)''$(segmt::in_sudo)''$(segmt::git_branch)''$(segmt::vim_mode)'
RPROMPT_LINE_OLD='$(segmt::in_vim)''$(segmt::in_sudo)'

# set prompts hooks

function set-normal-prompts
{
    PROMPT="${statuslineContainer}"$PROMPT_LINE
    RPROMPT=$RPROMPT_LINE
}
hooks-add-hook precmd_hook set-normal-prompts

function set-custom-prompts
{
    #set custom prompt
    PROMPT=$PROMPT_LINE_OLD
    RPROMPT=$RPROMPT_LINE_OLD

    zle reset-prompt
}
hooks-add-hook pre_accept_line_hook set-custom-prompts


#----------------------------------------------------------------------------------
# Status line
#----------------------------------------------------------------------------------

## TODO: where to put theses ?
# useful ANSI codes
#----------------------------------------

local _positionStatusbar=$'\e[$LINES;0H'
local _clearLine=$'\e[2K'
local _lineup=$'\e[1A'
local _linedown=$'\e[1B'
local _saveCursor=$'\e[s'
local _restoreCursor=$'\e[u'


#----------------------------------------
# StatusLine Config
#----------------------------------------

local slDefaultBG="$bg[magenta]"
local slDefaultFG=""


# TODO: 2 list of segmts for LeftStatusBar & RightStatusBar


local slResetColor="${reset_color}${slDefaultBG}${slDefaultFG}"

# statusline initializer
local initStatusline="${slResetColor}${_clearLine}"

#-------------------------------------------------------------
#

# The statusline content

# FIXME: YOU NEED TO CHANGE ONLY THIS LINE FIXME
local statusline='$(segmt::vim_mode)'"${slResetColor}"'$(segmt::time)'"${slResetColor}"'$(segmt::in_sudo)'"${slResetColor}""  "'$(segmt::last_exit_code)'

#
#-------------------------------------------------------------

# The statusline container
local statuslineContainer="%{${_saveCursor}${_positionStatusbar}${initStatusline}${statusline}${_restoreCursor}%}"

#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------

# NOTE: no idea where to put these..

# Reset Prompt every N seconds
#----------------------------------------

TMOUT=60

# This special function is run every $TMOUT seconds
function TRAPALRM
{
    # Reset prompt only when we are not in complete mode
    if [[ "$WIDGET" != 'expand-or-complete' ]]; then
        zle reset-prompt
    fi
}

# Set terminal title
#----------------------------------------

function set_title_on_idle
{
    term::set_status_line 'urxvt - %~'
}
hooks-add-hook precmd_hook set_title_on_idle

function set_title_on_exec
{
    local typed_cmd="$1"
    local expanded_cmd="$2"

    local cmd="$typed_cmd"

    # local truncation_offset=20
    # local truncated_cmd="%${truncation_offset}<...<$typed_cmd"
    term::set_status_line "urxvt - $cmd"
}
hooks-add-hook preexec_hook set_title_on_exec


#----------------------------------------------------------------------------------
# Misc
#----------------------------------------------------------------------------------


# load ssh keys in the current shell
#-------------------------------------------------------------
function loadsshkeys
{
    eval `ssh-agent`
    ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`
}


#----------------------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------------------

function no_output
{
    $@ >/dev/null 2>&1
}

function in_a_git_repo
{
    no_output git rev-parse --is-inside-work-tree
}

#----------------------------------------------------------------------------------
# ZLE Widgets
#----------------------------------------------------------------------------------

# Checks if we are in a git repository, displays a ZLE message otherwize.
function zle::utils::check_git
{
    if ! in_a_git_repo; then
        zle -M "Error: Not a git repository"
        return 1
    fi
}

# Toggle sudo at <bol>
function zwidget::toggle-sudo
{
    if [ "${BUFFER[1, 5]}" = "sudo " ]; then
        local cursor=$CURSOR
        BUFFER="${BUFFER[6, ${#BUFFER}]}"
        CURSOR=$(( cursor - 5 ))
    else
        local cursor=$CURSOR
        BUFFER="sudo $BUFFER"
        CURSOR=$(( cursor + 5 ))
    fi
}
zle -N zwidget::toggle-sudo

# Git status
function zwidget::git-status
{
    zle::utils::check_git || return

    echo # move cursor on a new line after the line editor
    git status
    zle reset-prompt
}
zle -N zwidget::git-status

# Git log
function zwidget::git-log
{
    zle::utils::check_git || return

    git l
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

    eval fg %+
    zle reset-prompt
}
zle -N zwidget::fg

# FG to the 2nd most recent ctrl-z'ed process
# fg %-
function zwidget::fg2
{
    [ -z "$(jobs)" ] && zle -M "No running jobs" && return
    [ "$(jobs | wc -l)" -lt 2 ] && zle -M "Not enough running jobs" && return

    eval fg %-
    zle reset-prompt
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
}
zle -N zwidget::cycle-quoting

#-------------------------------------------------------------
# Builtin ZLE wrappers
#-------------------------------------------------------------

# Accept Line Wrapper
#----------------------------------------
function accept-line
{
    hooks-run-hook pre_accept_line_hook
    zle .accept-line
    ZSH_CUR_KEYMAP=
}
zle -N accept-line

#----------------------------------------------------------------------------------
# Keybinds
#----------------------------------------------------------------------------------

# Enable vim mode
bindkey -v

# disable some keybinds
#-------------------------------------------------------------

bindkey -r '[29~' # Menu key


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
        KEYTIMEOUT=50 # 500ms
    fi
}
hooks-add-hook zle_keymap_select_hook helper::setup_keytimeout_per_keymap

function vibindkey
{
    bindkey -M viins $@
    bindkey -M vicmd $@
}
compdef _bindkey vibindkey

# TODO: better binds organization

vibindkey 's' zwidget::toggle-sudo

vibindkey 'q' zwidget::cycle-quoting

# fast git
vibindkey 'g' zwidget::git-status
vibindkey 'd' zwidget::git-diff
vibindkey 'D' zwidget::git-diff-cached
#vibindkey 'l' zwidget::git-log # handled by zwidget::go-right_or_git-log

autoload -U edit-command-line
zle -N edit-command-line

# Alt-E => edit line in $EDITOR
vibindkey 'e' edit-command-line

source ~/.zsh/fzf/key-bindings.zsh

vibindkey 'f' zwidget::fzf::file
vibindkey 'c' zwidget::fzf::directory
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
bindkey -M vicmd '#' push-input
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

# Accept the completion entry but continue to show the completion list
bindkey -M menuselect 'a' accept-and-hold


#----------------------------------------------------------------------------------

# Syntax hightlighting special end-of-file sourcing
#
# `zsh-syntax-highlighting.zsh` wraps ZLE widgets.
# It must be sourced after all custom widgets have been created (i.e., after
# all `zle -N` calls and after running `compinit`).
# Widgets created later will work, but will not update the syntax highlighting.
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
