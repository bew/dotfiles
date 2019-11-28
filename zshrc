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

fpath=(~/.zsh/fpath $fpath)

# Import color helpers
autoload -U colors && colors

# colors for common binaries (ls, tree, etc..)
if command -v dircolors >/dev/null; then
    DIRCOLORS_FILE=~/.dircolors
    ! [ -f $DIRCOLORS_FILE ] && dircolors -p > $DIRCOLORS_FILE
    [ -f $DIRCOLORS_FILE ] && eval `dircolors $DIRCOLORS_FILE`
fi

#----------------------------------------------------------------------------------
# Setup Hooks
#----------------------------------------------------------------------------------

# better zsh-hooks
source ~/.zsh/third-party/zsh-hooks/zsh-hooks.plugin.zsh

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

#----------------------------------------------------------------------------------
# Load Plugins
#----------------------------------------------------------------------------------

# cd with 'frecency' (recent + frequence)
#-------------------------------------------------------------
source ~/.zsh/third-party/z/z.sh

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

# # Slow version of git prompt
# source ~/.zsh/bin/git-prompt.sh # for __git_ps1
#
# # Show if there are unstaged (with *) and/or staged (with +) files
# GIT_PS1_SHOWDIRTYSTATE=1
#
# # Show if there are untracked (with %) files
# GIT_PS1_SHOWUNTRACKEDFILES=1

# Fast git status daemon!
source ~/.zsh/third-party/gitstatus/gitstatus.plugin.zsh
gitstatus_start MY


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

fpath=(~/.zsh/fpath-completion/ $fpath)

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
# Bracketed paste
#----------------------------------------------------------------------------------

# Override the default `bracketed-paste` widget, triggered when an external paste
# is incoming to the shell.

autoload -Uz bracketed-paste-url-magic

function my-bracketed-paste
{
    # Add an undo mark before receiving the pasted-content, so that the paste can
    # be easily undo-able without loosing anything I might have written before.
    zle split-undo

    # Use bracketed-paste-url-magic that does what bracketed-paste does but also
    # quotes the paste if it looks like a URL.
    bracketed-paste-url-magic
}

zle -N bracketed-paste my-bracketed-paste

#----------------------------------------------------------------------------------
# Aliases
#----------------------------------------------------------------------------------

function reload_zsh
{
    if [ -n "$(jobs)" ]; then
        echo "Error: $(jobs | wc -l) job(s) in background"
    else
        [[ -n "$ORIGINAL_PATH" ]] && export PATH="$ORIGINAL_PATH"
        exec zsh
    fi
}

alias zshrc=reload_zsh

# global aliases

alias -g nostdout=" >/dev/null "
alias -g nostderr=" 2>/dev/null "

# Shorters

alias g=git
alias gh=hub
alias m=make
alias dk=docker
alias dkc=docker-compose
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
alias l1="ls -1"

# misc

alias todo='rg -i "todo|fixme"'

function cheatsh
{
  curl cht.sh/$1
}

# Colorful diffs (https://www.colordiff.org/)
alias diff="colordiff"

# ping

alias pingonce="ping -c 1"
alias pg="ping google.fr"
alias ppg='prettyping google.fr'

# DNS lookup

# `dig` is deprecated on archlinux
if command -v drill >/dev/null; then
  alias dig=drill
fi

# mkdir

alias mkd="mkdir -p"

# Creates 1 or more directories, then cd into the first one
function mkcd
{
    mkd $*
    cd $1
}

# tree

alias tree="tree -C --dirsfirst -F"

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
        pacman -Qi $package | grep 'Description'
        echo
    done
}

alias pac::remove_useless_deps='command sudo pacman -Rsv $(pac::list_useless_deps)'

# yay

alias yay='yay --builddir ~/.long_term_cache/yay_build_dir'

# git

alias gnp='git --no-pager'
alias git::status_in_all_repos='find -name .git -prune -print -execdir git status \;'
alias git_watch='watch --color -- git --no-pager -c color.ui=always'

# sudo

# Makes sudo work with alias (e.g. 'sudo pac' => 'sudo pacman')
# Note: the trailing space is important (see the man for the zsh alias builtin)
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

# View file (read-only)
alias vw="nvim -R"

# launch editor (- let's try that!)
alias e="nvim"
alias er="nvim -R"

alias clean_swaps='rm ~/.nvim/swap_undo/swapfiles/.* ~/.nvim/swap_undo/swapfiles/*'

alias ":q"="exit"

# ncdu
alias ncdu='ncdu --color dark'

# youtube-dl

alias ytdl='youtube-dl'
alias ytdl-m4a='ytdl --extract-audio -f m4a --ignore-errors'
alias ytdl-m4a-nolist='ytdl-m4a --no-playlist'

# mpv

alias mpv-audio='mpv --no-video'
alias mpv-audio-loop='mpv-audio --loop-playlist'

# ffmpeg

alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'


# clock in terminal

alias clock='tty-clock -sc -C6 -d 0.5'
alias c=clock

# text translation (with https://github.com/soimort/translate-shell)

# translation
alias fr:en='trans fr:en -b'
alias en:fr='trans en:fr -b'
function fr:en:fr
{
  fr_en="$(fr:en $*)" && echo "en: $fr_en" && en:fr "$fr_en"
}
function en:fr:en
{
  en_fr="$(en:fr $*)" && echo "fr: $en_fr" && fr:en "$en_fr"
}

# definition
alias en:def='trans en: -d'
alias fr:def='trans fr: -d'

# misc

alias valgrindleak="valgrind --leak-check=full --show-reachable=yes"
alias cdgit='git rev-parse && cd "$(git rev-parse --show-toplevel)"'

alias makeawesome='make CMAKE_ARGS="-DLUA_LIBRARY=/usr/lib/liblua.so"'

function myip
{
  local ip=$(curl -s https://api.my-ip.io/ip.txt)
  echo "My public IP address is: $ip"
}

function weather
{
  if [[ $# == 0 ]]; then
    weather :help
    return
  fi

  local url="wttr.in/$1?format=v2"
  echo "Getting weather using url: $url"
  curl "$url"
}

# Hacks

# 'pezop' is a firefox profile, where the browser language is in french, to
# bypass language limitations on www.rotazu.com :)
alias ff_streaming="firefox -P pezop www.diagrim.com &!"


# Fast config edit

alias vimzshrc="vim ~/.zshrc"
alias vimnviminit="vim ~/.config/nvim/init.vim"
alias vimnvimmappings="vim ~/.config/nvim/config.rc/mappings.rc.vim"
alias cdzsh="cd ~/.zsh"
alias cdnvim="cd ~/.nvim"
alias cdbin="cd ~/.bin"

# helper aliases

# Allow alias expansion
#
# So I can do: `dl_fast_then_slow.sh ytdl <link>`
alias dl_fast_then_slow.sh='dl_fast_then_slow.sh '

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

# Mesure time (arbitrarily)

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
    if [[ "$color_mode" =~ "Usage" ]]; then
        echo $color_mode # print error
        return 1
    else
        export TERM_COLOR_MODE=$color_mode
    fi
}

function transfer
{
    if [ $# -eq 0 ]; then
        echo "No arguments specified."
        echo
        echo "Usages: Given \`echo some content > /tmp/test.md\`"
        echo "  1. cat /tmp/test.md | transfer some_name"
        echo "  2. transfer /tmp/test.md"
        echo
        return 1;
    fi

    tmpfile=$( mktemp -t transferXXX );
    if tty -s; then
        # input is from given file
        basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g');
        command curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile;
    else
        # input is from stdin
        command curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ;
    fi;
    echo
    command cat $tmpfile;
    command rm -f $tmpfile;
    echo
}

function http::serve-local
{
  if [[ $# == 0 ]]; then
    echo "Usage: $0 <directory> [<port> [<ip>|all]]"
    return 1
  fi

  # NOTE: We force <dir> to be specified to have a no-arg form that gives the usage message

  local dir="$1"
  local port="${2:-1234}"
  local ip="${3:-127.0.0.1}"
  [[ "$ip" == "all" ]] && ip="0.0.0.0"

  echo "==> Serving '$dir' on '$ip:$port' over HTTP <=="
  echo

  python -m http.server $port --bind $ip --directory $dir
}

# Extract common compressed file formats
function extract
{
  local dryrun=0
  if [[ "$1" == "--dry-run" ]]; then
    dryrun=1
    shift
  fi

  if [[ $# == 0 ]]; then
    echo "Usage: extract [--dry-run] <compressed_file> [<directory>]"
    return 1
  fi

  local compressed_file="$1"
  local target_dir="${2:-.}"
  local source_dir="$PWD"

  echo "--> Extracting '$compressed_file' to '$target_dir'..."
  [[ "$dryrun" == 1 ]] && return

  mkdir -vp "$target_dir" || return 1

  case "$compressed_file" in
    (*.tar)
      tar xvf "$compressed_file" -C "$target_dir"
      ;;
    (*.tar.gz|*.tgz)
      tar xvzf "$compressed_file" -C "$target_dir"
      ;;
    (*.tar.bz2|*.tbz|*.tbz2)
      tar --bzip2 xvf "$compressed_file" -C "$target_dir"
      ;;
    (*.tar.xz|*.txz)
      tar --xz xvf "$compressed_file" -C "$target_dir"
      ;;

    (*.zip)
      unzip "$compressed_file" -d "$target_dir"
      ;;

    (*.rar)
      (cd "$target_dir" && unrar e "${source_dir}/${compressed_file}")
      ;;

    (*.7z)
      7z e -o"$target_dir" "$compressed_file"
      ;;

    # Single file extractors
    (*.gz)
      local target_file="${compressed_file%.gz}" # remove extension
      gunzip --stdout "${compressed_file}" > "${target_dir}/${target_file}"
      ;;
    (*.bz2)
      local target_file="${compressed_file%.bz2}" # remove extension
      gunzip --stdout "${compressed_file}" > "${target_dir}/${target_file}"
      ;;
    (*.xz)
      local target_file="${compressed_file%.xz}" # remove extension
      unxz --stdout "${compressed_file}" > "${target_dir}/${target_file}"
      ;;

    (*)
      echo "ERROR: Unsupported file extension '$compressed_file'"
      return 1
      ;;
  esac
}
alias extract::dry-run='extract --dry-run'

# ------------------------------------------------------------------------
# ffmpeg helpers

function ffmpeg::extract-audio
{
    if [[ $# == 0 ]]; then
        echo "Usage: ffmpeg::extract-audio <filename> [<format>]"
        echo "  <format> defaults to m4a"
        return 1
    fi

    local filename="$1"
    local format="${2:-m4a}"
    local target_filename="${filename}.${format}"

    echo ">>> Extracting audio from '$filename'..."

    # -i    input file
    # -vn   disable video
    ffmpeg -hide_banner -i "$filename" -vn "$target_filename"
    local ret=$?
    if [[ $? == 0 ]]; then
        echo " >> Audio extracted to '$target_filename'."
    else
        echo " >> Audio extract from '$filename' failed."
    fi
    return $ret
}

function ffmpeg::extract-audio::rm_source
{
    local filename="$1"
    local format="${2:-m4a}"

    ffmpeg::extract-audio "$filename" "$format"
    local ret=$?
    if [[ $? == 0 ]]; then
        echo ">>> Deleting source '$filename'..."
    else
        return $ret
    fi

    command rm "$filename"
    ret=$?
    [[ $ret == 0 ]] && echo " >> Done!"
    return $ret
}

# ------------------------------------------------------------------------
# mpv daemon player
#
# Example usage:
# ```zsh
# # Start the daemon in a separate terminal
# $ mpv::start-daemon music
#
# # And then
# $ mpv::add-media music file1 file2 file3
#
# # Enjoy!
# ```
#
# The idea of channels is to be able to remote control multiple mpv instance,
# e.g: one for music, one for some films, one for youtube videos, ...

# Start an mpv instance in daemon mode identified by channel $1
function mpv::start-daemon
{
    local channel=${1:-default}; [[ -n "$1" ]] && shift
    local ipc_socket="/tmp/mpv-socket-${channel}"

    echo ">>> Starting mpv daemon for channel '$channel' on IPC socket '$ipc_socket'..."
    mpv --idle --input-ipc-server="$ipc_socket" $*
}

# Send an arbitrary command to mpv on channel $1
#
# For command documentation checkout `man mpv` section "JSON IPC"
function mpv::send_command
{
    if [[ $# == 0 ]] || [[ $# == 1 ]]; then
        echo "Usage: $0 <channel> <command> [<arg> ...]"
        return 1
    fi

    local channel=$1; shift
    local ipc_socket="/tmp/mpv-socket-${channel}"

    local json='{"command": ['
    for cmd_part in $*; do
        # qqq to add double quotes for json strings
        json+="${(qqq)cmd_part}, "
    done
    [[ $# != 0 ]] && json="${json[1, -3]}" # remove last ', '
    json+="] }"

    # echo "JSON: $json" >&2

    echo "$json" | socat - "$ipc_socket"
}

# Helper function to make sure the mpv instance on channel $1 exists
#
# Exits with non-0 if it doesn't exist.
function mpv::ensure-socket-exist
{
    local channel=$1
    local ipc_socket="/tmp/mpv-socket-${channel}"

    # -S   : socket
    if ! [[ -S "$ipc_socket" ]]; then
        echo >&2 ">>> ERROR: mpv channel '$channel' invalid"
        echo >&2 "     -> '$ipc_socket' is not an mpv IPC socket."
        return 1
    fi
}

# Add any number of medias to mpv on channel $1,
# then start playback if the playlist was empty before.
function mpv::add-media
{
    if [[ $# == 0 ]]; then
        echo "Usage: $0 <channel> <path> [<path> ...]"
        return 1
    fi

    local channel=$1; shift

    mpv::ensure-socket-exist $channel || return 1

    echo ">>> Adding medias to mpv on channel '$channel'"

    local ret
    for media_path in $*; do
        local media_full_path=$(realpath "$media_path")
        echo ">>> Appending media '$media_path'"
        mpv::send_command $channel "loadfile" "$media_full_path" "append-play"
        ret=$?
        [[ $ret != 0 ]] && return $ret
    done

    echo ">>> All medias added!"
}

# Show the playlist of mpv on channel $1
function mpv::show-playlist
{
    if [[ $# == 0 ]]; then
        echo "Usage: $0 <channel>"
        return 1
    fi

    local channel=$1

    mpv::ensure-socket-exist "$channel" || return 1

    local output=$(mpv::send_command $channel "get_property" "playlist")

    local ret=$?
    [[ $ret != 0 ]] && return $ret

    echo "$output" | jq . # let's just pretty print it for now...
}

alias tv-start='mpv::start-daemon tv --no-terminal --force-window'
alias tv-add='mpv::add-media tv'

# ------------------------------------------------------------------------

# Import zsh's massive rename helper
autoload -U zmv
alias zmv='noglob zmv'
alias zcp='zmv -C'
alias zln='zmv -L'
alias zmv::dry-run='zmv -n'
alias zcp::dry-run='zcp -n'
alias zln::dry-run='zln -n'


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
function segmt::git_branch_slow
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

# Segment git branch (fast!)
function segmt::git_branch_fast
{
    [ -n "$NO_SEGMT_GIT_BRANCH" ] && return

    emulate -L zsh
    typeset -g GITSTATUS_PROMPT=""

    # Call gitstatus_query synchronously. Note that gitstatus_query can also be called
    # asynchronously; see documentation in gitstatus.plugin.zsh.
    gitstatus_query MY                  || return 1  # error
    [[ $VCS_STATUS_RESULT == ok-sync ]] || return 0  # not a git repo

    local       clean='%F{076}'  # green foreground
    local c_untracked='%F{014}'  # teal foreground
    local  c_modified='%F{011}'  # yellow foreground

    local p
    if (( VCS_STATUS_HAS_STAGED || VCS_STATUS_HAS_UNSTAGED )); then
        p+=$c_modified
    elif (( VCS_STATUS_HAS_UNTRACKED )); then
        p+=$c_untracked
    else
        p+=$clean
    fi
    local current_ref="${VCS_STATUS_LOCAL_BRANCH:-@${VCS_STATUS_COMMIT}}"
    [[ -n $VCS_STATUS_TAG ]] && current_ref+="#${VCS_STATUS_TAG}"

    p+=${current_ref//\%/%%}  # escape %

    local repo_status
    [[ $VCS_STATUS_HAS_STAGED      == 1 ]] && repo_status+="${c_modified}+"
    [[ $VCS_STATUS_HAS_UNSTAGED    == 1 ]] && repo_status+="${c_modified}!"
    [[ $VCS_STATUS_HAS_UNTRACKED   == 1 ]] && repo_status+="${c_untracked}?"
    [[ -n "$repo_status" ]] && p+=" ${repo_status}${clean}"

    [[ $VCS_STATUS_COMMITS_AHEAD  -gt 0 ]] && p+=" ⇡${VCS_STATUS_COMMITS_AHEAD}"
    [[ $VCS_STATUS_COMMITS_BEHIND -gt 0 ]] && p+=" ⇣${VCS_STATUS_COMMITS_BEHIND}"
    [[ $VCS_STATUS_STASHES        -gt 0 ]] && p+=" *${VCS_STATUS_STASHES}"

    echo -n "%K{black} On ${p} %k"
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
        local content="Last Exit: ${LAST_EXIT_CODE}"
        local with_style="%B%K{black}%F{red} ${content} %f%k%b"
        echo -n "${with_style}"
    fi
}

# Segment last exit code
function segmt::exit_code_on_error
{
  [[ $LAST_EXIT_CODE == 0 ]] && return

  local content="✘"
  local with_style="%K{124} ${content} %k"
  echo -n "${with_style}"
}

# Segment is shell in sudo session
function segmt::in_sudo
{
    local result=$(sudo -n echo -n bla 2>/dev/null)

    if [[ "$result" == "bla" ]]; then
        local content="In sudo"
        local with_style="%K{red}%F{white}%B $content %b%f%k"
        echo -n "$with_style"
    fi
}

# Segment prompt vim mode (normal/insert)
function segmt::vim_mode
{
    local insert_mode_style="%B%K{green}%F{white} INSERT %f%k%b"
    local normal_mode_style="%B%K{blue}%F{white} NORMAL %f%k%b"

    if [[ -z "$KEYMAP" ]] || [[ "$KEYMAP" =~ "(main|viins)" ]]; then
        echo -n ${insert_mode_style}
    elif [[ "$KEYMAP" == "vicmd" ]]; then
        echo -n ${normal_mode_style}
    else
        echo -n "$KEYMAP"
    fi
}

# Segment prompt vim mode (normal/insert)
function segmt::short_vim_mode
{
    local insert_mode_style="%B%K{green}%F{white} I %f%k%b"
    local normal_mode_style="%B%K{blue}%F{white} N %f%k%b"

    if [[ -z "$KEYMAP" ]] || [[ "$KEYMAP" =~ "(main|viins)" ]]; then
        echo -n ${insert_mode_style}
    elif [[ "$KEYMAP" == "vicmd" ]]; then
        echo -n ${normal_mode_style}
    else
        echo -n "$KEYMAP"
    fi
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
    local with_style="%B%F{red}${shlvl} %f%b"

    echo -n "${with_style}"
}

# Segment datetime
function segmt::time
{
    local currentTime=$(date "+%H:%M [%d/%m]")
    local currentTimeStyle=" ${currentTime} "
    echo -n "${currentTimeStyle}"
}

# Segment variable debug
function segmt::debug
{
    local debugVar=$*
    local debugVarStyle="%K{blue} DEBUG: ${debugVar} %k"
    echo -n "${debugVarStyle}"
}

# Build a string from an array of parts.
# A part can be a function or a simple text.
#
# Args: (reset_code, *parts)
# - reset_code: The reset code to add after a function call (e.g: color reset).
# - *parts: The parts as described below.
#
# Each part uses 2 elements in the parts array for the type and the value.
# The types of parts are:
# - func : a function call
# - text : raw text
# In addition there are special parts that configures parts rendering:
# - part_separator : separator between parts
# - func_reset : reset sequence inserted after a func call
# - (TODO ?: part_reset)
#
# Example:
#
#   parts=(
#     # change part config
#     part_separator: "|"
#     func_reset: "reset"
#
#     func: some_func1
#     func: some_func2
#     text: "xxx"
#
#     # change part config
#     func_reset: "XX"
#
#     func: some_func3
#   )
#   make_prompt_str_from_parts "${parts[@]}"
#
# Gives literaly:
#
#   $(some_func1)reset|$(some_func2)reset|xxx|$(some_func3)reset
#
# The result will need to be re-evaluated by the prompt system to call
# the functions (some_func{1,2,3}).
#
# TODO: (oneday) allow func args, like:
#   func: 2 some_func arg1 arg2
function make_prompt_str_from_parts
{
  local parts=("$@")

  local str
  local func_reset
  local part_separator
  local user_part_idx=0 # user parts, skipping config parts

  local len_parts=${#parts}
  if (( len_parts % 2 != 0 )); then
    echo >&2 "Error while making prompt str from parts, invalid length of parts (${#parts} - must be divisible by 2)"
    echo "foo"
    return 1
  fi

  while [[ ${#parts} -ne 0 ]]; do
    # read the part as "type: value"
    local type="${parts[1]}"
    local value="${parts[2]}"
    shift 2 parts # NOTE: zsh only! bash does not accept array name

    # No part separator before the first user part
    local maybe_separator="$part_separator"
    [[ "$user_part_idx" == 0 ]] && maybe_separator=""

    case "$type" in
      # Config parts handling
      func_reset:) func_reset="$value" ;;
      part_separator:) part_separator="$value" ;;

      # User parts handling
      func:)
        user_part_idx=$(( user_part_idx + 1 ))
        str+="$maybe_separator"
        str+='$('"$value"')'
        str+="$func_reset"
        ;;
      text:)
        user_part_idx=$(( user_part_idx + 1 ))
        str+="$maybe_separator"
        str+="$value"
        ;;
    esac
  done

  echo -n $str
}

## Prompts & Status line
##############################################
#
#  %B (%b)
#         Start (stop) boldface mode.
#
#  %E     Clear to end of line.
#
#  %U (%u)
#         Start (stop) underline mode.
#
#  %S (%s)
#         Start (stop) standout mode.
#
#  %F (%f)
#         Start  (stop) using a different foreground colour, if supported by the terminal.  The colour may be specified two ways: either as a numeric argument, as normal, or by a
#         sequence in braces following the %F, for example %F{red}.  In the latter case the values allowed are as described for the  fg  zle_highlight  attribute;  see  Character
#         Highlighting in zshzle(1).  This means that numeric colours are allowed in the second format also.
#
#  %K (%k)
#         Start (stop) using a different bacKground colour.  The syntax is identical to that for %F and %f.

autoload -U promptinit && promptinit

# -- Status line

STATUSLINE_PARTS=(
  func: segmt::vim_mode
  func: segmt::time
  func: segmt::in_sudo
  text: "  "
  func: segmt::last_exit_code
)

# NOTE: the generated prompt str is static, the segment functions are not called.
function sl::build_prompt_str
{
  local _cur_save=$'\e[s'
  local _cur_restore=$'\e[u'
  local _goto_bottom=$'\e[$LINES;0H'
  local _clear_line=$'\e[2K'

  local sl_default_bg="${bg[magenta]}"
  local sl_default_fg=""

  local sl_color="${reset_color}${sl_default_bg}${sl_default_fg}"

  local sl_init="${sl_color}${_clear_line}"

  local sl_content="$(make_prompt_str_from_parts func_reset: "$sl_color" "${STATUSLINE_PARTS[@]}")"

  local sl_container="${_cur_save}${_goto_bottom}${sl_init}${sl_content}${_cur_restore}"
  echo -n "%{${sl_container}%}"
}

# -- Left prompt

PROMPT_CURRENT_PARTS=(
  func: segmt::shlvl
  func: segmt::exit_code_on_error
  text: "[%F{yellow}%n%f]" # username
  text: " "
  text: "%2~" # current dir
  text: " "
  text: "%(!.#.▷)"
)
PROMPT_PAST_PARTS=(
  func: segmt::shlvl
  func: segmt::exit_code_on_error
  text: "%K{black}%B%F{cyan} %2~ %f%b%k" # current dir
  text: " "
  text: "%B%F{magenta}%%%f%b" # cmd separator
)

PROMPT_CURRENT="$(sl::build_prompt_str)""$(make_prompt_str_from_parts "${PROMPT_CURRENT_PARTS[@]}")"
PROMPT_PAST="$(make_prompt_str_from_parts "${PROMPT_PAST_PARTS[@]}")"

# Add space before user input
PROMPT_CURRENT+=" "
PROMPT_PAST+=" "

# -- Right prompt

RPROMPT_CURRENT_PARTS=(
  func_reset: "%{$reset_color%}"

  func: segmt::in_sudo
  func: segmt::git_branch_fast
  func: segmt::vim_mode
)

RPROMPT_PAST_PARTS=(
  func_reset: "%{$reset_color%}"

  func: segmt::in_sudo
  func: segmt::git_branch_fast
)

RPROMPT_CURRENT="$(make_prompt_str_from_parts "${RPROMPT_CURRENT_PARTS[@]}")"
RPROMPT_PAST="$(make_prompt_str_from_parts "${RPROMPT_PAST_PARTS[@]}")"
# RPROMPT_CURRENT='$(segmt::in_sudo)''$(segmt::git_branch_fast)''$(segmt::vim_mode)'
# RPROMPT_PAST='$(segmt::in_sudo)''$(segmt::git_branch_fast)'

# -- Setup prompts hooks

function set-current-prompts
{
    PROMPT="%{$reset_color%}"$PROMPT_CURRENT
    RPROMPT="%{$reset_color%}"$RPROMPT_CURRENT
}
hooks-add-hook precmd_hook set-current-prompts

function set-past-prompts
{
    # Set past prompt
    PROMPT="%{$reset_color%}"$PROMPT_PAST
    RPROMPT="%{$reset_color%}"$RPROMPT_PAST

    zle reset-prompt
}
hooks-add-hook zle_line_finish_hook set-past-prompts

function simple_prompts
{
  PROMPT_CURRENT="%2~ ▷ "
  PROMPT_PAST=$PROMPT_CURRENT
  RPROMPT_CURRENT=
  RPROMPT_PAST=
}


# Reset Prompt every N seconds
#----------------------------------------

# TODO: use sched!

TMOUT=60

# This special function is run every $TMOUT seconds
function TRAPALRM
{
    # Don't reset prompt when we are in complete mode
    [[ "$WIDGET" == 'expand-or-complete' ]] && return

    # Don't reset prompt when a widget uses the space (e.g: by running another program like fzf)
    # (A prompt reset might hide the program or conflict with its output)
    helper::is-prompt-autoupdate-disabled && return

    zle reset-prompt
}

# NOTE: !WIP! this is currently not used!!!
function helper::disable-prompt-autoupdate
{
    DISABLE_PROMPT_AUTOUPDATE=1
}
function helper::enable-prompt-autoupdate
{
    DISABLE_PROMPT_AUTOUPDATE=
}
function helper::is-prompt-autoupdate-disabled
{
    [[ -n "$DISABLE_PROMPT_AUTOUPDATE" ]]
}
function helper::with-prompt-autoupdate-disabled-do
{
  helper::disable-prompt-autoupdate
  "$@"
  helper::enable-prompt-autoupdate
}
function failsafe-reenable-prompt-autoupdate
{
    # Re-enable prompt autoupdate.
    #
    # It is needed when a widget disabled prompt autoupdate then crashed,
    # thus failed to re-enable it.
    helper::enable-prompt-autoupdate
}
hooks-add-hook zle_line_init_hook failsafe-reenable-prompt-autoupdate

# Set terminal title
#----------------------------------------

function set_title_on_idle
{
    term::set_status_line 'term - %~'
}
hooks-add-hook precmd_hook set_title_on_idle

function set_title_on_exec
{
    local typed_cmd="$1"
    local expanded_cmd="$2"

    local cmd="$typed_cmd"

    # local truncation_offset=20
    # local truncated_cmd="%${truncation_offset}<...<$typed_cmd"
    term::set_status_line "term - $cmd"
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

# Check if the ssh agent should be running but is dead
#
# For example: after a 'stupid' `pkill ssh`, the env var SSH_AGENT_PID will still
# exist, the target pid does not exist anymore thenks to pkill.
if [[ -n "$SSH_AGENT_PID" ]] && ! kill -0 "$SSH_AGENT_PID" >& /dev/null; then
  echo "The ssh agent should be running but is dead, reloading ssh keys!"
  loadsshkeys >& /dev/null
fi


#----------------------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------------------

function no_output
{
    "$@" >/dev/null 2>&1
}

function check::in_a_git_repo
{
    no_output git rev-parse --is-inside-work-tree
}

#----------------------------------------------------------------------------------
# ZLE Widgets
#----------------------------------------------------------------------------------

# Helper widget that calls another widget while disabling prompt auto-refresh until the widget is finished
function zle::utils::wrap-widget-disable-prompt-autoupdate
{
    local widget_to_call=$1

    eval "
    function ${widget_to_call}_wrapped
    {
        helper::disable-prompt-autoupdate

        zle $widget_to_call -w \$*

        helper::enable-prompt-autoupdate
    }
    "
    zle -N ${widget_to_call}_wrapped
}
# NOTE: !WIP! this is currently not used!!!

# Checks if we are in a git repository, displays a ZLE message otherwize.
function zle::utils::check_git
{
    if ! check::in_a_git_repo; then
        zle -M "Error: Not a git repository"
        return 1
    fi
}

# Toggle sudo at <bol>
function zwidget::toggle-sudo
{
    # Overwriting BUFFER will reset CURSOR to <bol>
    # so we store its original position first
    local cursor=$CURSOR

    if [ "${BUFFER[1, 5]}" = "sudo " ]; then
        BUFFER="${BUFFER[6, ${#BUFFER}]}"
        CURSOR=$(( cursor - 5 ))
    else
        BUFFER="sudo $BUFFER"
        CURSOR=$(( cursor + 5 ))
    fi
}
zle -N zwidget::toggle-sudo

# Git status
function zwidget::git-status
{
    zle::utils::check_git || return

    zle -I # Invalidate zle display
    git status
    zle reset-prompt
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

    zle -I
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

    zle -I
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
    zle reset-prompt
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

#----------------------------------------------------------------------------------
# Keybinds
#----------------------------------------------------------------------------------

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
    bindkey -M viins $@
    bindkey -M vicmd $@
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

source ~/.zsh/fzf/key-bindings.zsh

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

# Accept the completion entry but continue to show the completion list
bindkey -M menuselect 'a' accept-and-hold


#----------------------------------------------------------------------------------
# Load local per-machine zsh config

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

#----------------------------------------------------------------------------------

# Syntax hightlighting special end-of-file sourcing
#
# `zsh-syntax-highlighting.zsh` wraps ZLE widgets.
# It must be sourced after all custom widgets have been created (i.e., after
# all `zle -N` calls and after running `compinit`).
# Widgets created later will work, but will not update the syntax highlighting.
source ~/.zsh/third-party/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
