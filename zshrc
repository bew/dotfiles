########################################################################################
#|#                                                                                    #|#
#|#  ::::::::: ::::::::  :::    :::       ::::::::   ::::::::  ::::    ::: ::::::::::  #|#
#|#       :+: :+:    :+: :+:    :+:      :+:    :+: :+:    :+: :+:+:   :+: :+:         #|#
#|#      +:+  +:+        +:+    +:+      +:+        +:+    +:+ :+:+:+  +:+ +:+         #|#
#|#     +#+   +#++:++#++ +#++:++#++      +#+        +#+    +:+ +#+ +:+ +#+ :#::+::#    #|#
#|#    +#+           +#+ +#+    +#+      +#+        +#+    +#+ +#+  +#+#+# +#+         #|#
#|#   #+#     #+#    #+# #+#    #+#      #+#    #+# #+#    #+# #+#   #+#+# #+#         #|#
#|#  ######### ########  ###    ###       ########   ########  ###    #### ###         #|#
#|#                                                                                    #|#
########################################################################################

export SHELL=zsh
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
unsetopt beep

bindkey -v

# Autoload

autoload -U colors && colors
autoload -U compinit && compinit
zmodload zsh/complist



# colors for common binaries (ls, tree, etc..)
! [ -f ~/.dircolors ] && dircolors -p > ~/.dircolors
[ -f ~/.dircolors ] && eval `dircolors ~/.dircolors`



#----------------------------------------------------------------------------------
# LOAD PLUGINS
#----------------------------------------------------------------------------------

# Add vim obj (ciw / ciW / etc...)
#-------------------------------------------------------------
source ~/.zsh/opp.zsh/opp.zsh


# smart cd
#-------------------------------------------------------------
source ~/.zsh/z/z.sh

# Syntax hightlighting
#-------------------------------------------------------------
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Configuration
#----------------------------------------

# Enable highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# Override highlighter colors
ZSH_HIGHLIGHT_STYLES[default]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=009,standout
ZSH_HIGHLIGHT_STYLES[alias]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=cyan
ZSH_HIGHLIGHT_STYLES[command]=fg=blue,bold
ZSH_HIGHLIGHT_STYLES[precommand]=fg=white,underline
ZSH_HIGHLIGHT_STYLES[commandseparator]=none
ZSH_HIGHLIGHT_STYLES[hashed-command]=fg=009
ZSH_HIGHLIGHT_STYLES[path]=fg=yellow
ZSH_HIGHLIGHT_STYLES[globbing]=fg=063
ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=white,underline
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=fg=blue
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=063
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=063
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=009
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=009
ZSH_HIGHLIGHT_STYLES[assign]=none


# advanced zsh-hooks
##############################################
source ~/.zsh/zsh-hooks/zsh-hooks.plugin.zsh


#----------------------------------------------------------------------------------
# UTILS
#----------------------------------------------------------------------------------

# Get the cursor position on the terminal.
#
# It saves the result in CURSOR_POS_ROW & CURSOR_POS_COL
#-------------------------------------------------------------
# FIXME: if the read buffer is not empty, it discard it
#-------------------------------------------------------------
function get_cursor_pos()
{
	echo -en "\e[6n"; read -u0 -sd'[' _; read -u0 -sdR pos

	# pos has format 'row;col'
	CURSOR_POS_ROW=${pos%;*} # remove ';col'
	CURSOR_POS_COL=${pos#*;} # remove 'row;'
}

# TODO: move this in the prompt module
function regen-prompt()
{
	zle reset-prompt
}

#----------------------------------------------------------------------------------
# Setup Hooks
#----------------------------------------------------------------------------------

## ZSH HOOKS

# precmd_hook
hooks-define-hook precmd_hook
function precmd-wrapper() { hooks-run-hook precmd_hook }
add-zsh-hook precmd precmd-wrapper

# preexec_hook
hooks-define-hook preexec_hook
function preexec-wrapper() { hooks-run-hook preexec_hook }
add-zsh-hook preexec preexec-wrapper

# chpwd_hook
hooks-define-hook chpwd_hook
function chpwd-wrapper() { hooks-run-hook chpwd_hook }
add-zsh-hook chpwd chpwd-wrapper

# CUSTOM HOOKS
#-------------------------------------------------------------

hooks-define-hook pre_accept_line_hook

#----------------------------------------------------------------------------------
# Options
#----------------------------------------------------------------------------------

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

# TODO: search what they do
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST

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

# Required for global alias completion: m c<TAB>
# Unknown why it destroy completion....
#setopt COMPLETE_ALIASES




#----------------------------------------------------------------------------------
# Aliases
#----------------------------------------------------------------------------------

alias zshrc="source ~/.zshrc"


# Tek piscine easy

alias gccw="g++ *.cpp -Werror -Wextra -g3 -Wall -W && echo ok"


# global aliases

alias -g nostdout=" >/dev/null "
alias -g nostderr=" 2>/dev/null "

# Short aliases

alias G="realgrep"
alias A="ack"
alias H="head"
alias T="tail"
alias L="less"
alias V="vim"

# add verbosity

alias cp="cp -vi"
alias mv="mv -vi"
alias mkdir="mkdir -v"

# use ack instead !!
alias realgrep="command grep --color=auto -n"
alias grep="echo Use ack"

# ls

alias ls="ls --color=auto --group-directories-first"
alias lsl="ls -lh"
alias ll="lsl"
alias lll="clear; ll"
alias la='lsl -a'
alias l="la"
alias ls1="ls -1"
alias clsl="clr && pwd && lsl"

#

alias j="jobs"

alias todo="ack -i 'todo|fixme'"

# term

alias xt="xterm&"
alias clr="clear"

# ping

alias pg="ping google.fr"
alias pgc="pg -c 1 -w 5"

# mkdir

alias mkd="mkdir -p"

function mkcd()
{
	mkd $*
	cd $1
}

# for emacs users :p
alias ne="echo 'Use: vim'"

# tree

alias tree="tree -C --dirsfirst -F"
alias tre="tree"

# cd

alias ..="cd ..;"
alias ...="cd ../..;"
alias ....="cd ../../..;"

# pacman

alias pacman="sudo pacman"

# Remove useless packages
alias pacmanuseless="pacman -Rnsv \$(pacman -Qtdq)"


# Close the current sudo session if any
alias nosudo="sudo -k"


# google search
function gg()
{
	chromium "google.fr/#q=$1" 2> /dev/null
}

# history search
function hsearch()
{
	if test "$1" = ""; then
		history 1
	else
		history 1 | \grep --color=auto $1
	fi
}


# vim

alias vim="vim -X"
alias vim=nvim
alias v="vim"
alias im="v"
alias vm="v"
alias vi="v"
alias vmi="v"
alias imv="v"
alias ivm="v"

alias view="vim -R -c 'set nomod nolist'"

alias ":h"="vimhelp"
alias ":q"="exit"

# man in vim
function man()
{
	/usr/bin/man $* | col -bp | vim -R -c "set ft=man" -
}
# man completion
compdef _man man


# tek clone
function epiclone
{
	echo "$fg[blue]Cloning from git@git.epitech.eu:$fg[yellow]$*$reset_color"
	git clone git@git.epitech.eu:$*
}

# wpa
alias wpa=wpa_cli

# make

alias make="make"
alias m=make
alias remake="make --silent fclean; make -j all > /dev/null; clean .o > /dev/null"
alias remkae="remake"
alias remaek="remake"

#

# norme
alias nall="n $* \$(tree -if) -libc"

alias cl="clean"

alias valgrindleak="valgrind --leak-check=full --show-reachable=yes"

alias zut="sudo !!"

# git

alias cdgit='git rev-parse && cd "$(git rev-parse --show-toplevel)"'

alias g="git"
alias gti="git"
alias gitcheck="git checkout"
alias gitadl="git add --all"
alias gitai="git add -i"

alias gitstatus="git status --ignore-submodules"
alias gitstatusall="gitstatus -u" # show all untracked files
alias gitdiff="git diff --word-diff=color --ignore-all-space"

alias gitbranch="git branch -vv"

alias gitlog="git log --graph --abbrev-commit --decorate --format=format:'%C(bold red)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%n' --all"

alias gitlogstat="gitlog --stat"

alias gitfetch="git fetch"
alias gitpush="git push"
alias gitpull="git pull"
alias gitph="gitpush"
alias gitpl="gitpull"

alias push="gitpush"

# cwd

function cpwd ()
{
	echo \"$(pwd)\" copied into X primary clipboard;
	pwd | xclip -in -selection primary;
}

alias cdwd="cd \$(xclip -out -selection primary) && echo 'Moved to' \$(pwd)"


# Fast config edit

alias vimzshrc="vim ~/.zshrc"
alias vimvimrc="vim ~/.vimrc"


#----------------------------------------------------------------------------------
# Completion
#----------------------------------------------------------------------------------

# menu completion style
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors yes

# Directories first when completing files
zstyle ':completion:*' list-dirs-first on

# formatting and messages
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
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:original' list-colors "=*=$color[red];$color[bold]"
zstyle ':completion:*:commands' list-colors "=*=$color[green];$color[bold]"
zstyle ':completion:*:builtins' list-colors "=*=$color[cyan];$color[bold]"
zstyle ':completion:*:functions' list-colors "=*=$color[cyan]"
zstyle ':completion:*:parameters' list-colors "=*=$color[red]"
zstyle ':completion:*:aliases' list-colors "=*=$color[cyan];$color[bold]"
zstyle ':completion:*:reserved-words' list-colors "=*=$color[magenta]"

zstyle ':completion:*:options' list-colors "=^(-- *)=$color[green]"

zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'

# Vim ignore files for completion
#----------------------------------------

local vimIgnore='*.pdf'

# Ignore *.o & *.pdf on file complete, when completing vim
vimIgnore="$vimIgnore"'|*.o'

# Ignore OCaml compilations files
vimIgnore="$vimIgnore"'|*.cmx|*.cmi|*.cmo'


zstyle ':completion:*:*:vim:*:*files' ignored-patterns ${vimIgnore}

#----------------------------------------------------------------------------------
# Custom segments (not zle)
#----------------------------------------------------------------------------------

# Git branch
#-------------------------------------------------------------

# Segment git branch
source ~/.zsh/bin/git-prompt.sh

function segmt_git_branch
{
	local branchName=$(__git_ps1 "%s")
	if [[ -z ${branchName} ]]; then
		return
	fi
	local branchNameStyle="%{$fg[red]%}${branchName}"

	local gitInfo=" On ${branchNameStyle} "
	local gitInfoStyle="%{$bg[black]%}${gitInfo}%{$reset_color%}"

	echo -n ${gitInfoStyle}
}

# Segment last exit code
function segmt_last_exit_code()
{
	if [[ $LAST_EXIT_CODE -ne 0 ]]; then
		local lastExitCode="Last Exit: ${LAST_EXIT_CODE}"
		local lastExitCodeStyle="%{$bg[black]$fg_bold[red]%} ${lastExitCode} %{$reset_color%}"
		echo -n ${lastExitCodeStyle}
	fi
}

# Segment is shell in vim
function segmt_in_vim
{
	if [[ $VIM != "" ]]; then
		echo -n " In Vim "
	fi
}

# Segment is shell in sudo session
function segmt_in_sudo
{
	local result=$(sudo -n echo -n bla 2>/dev/null)
	if test "$result" = "bla"; then
		local inSudo="In sudo"
		local inSudoStyle="%{$bg[red]$fg_bold[white]%} $inSudo %{$reset_color%}"
		echo $inSudoStyle
	fi
}

# Segment prompt vim mode (normal/insert)
function segmt_vim_mode()
{
	local keymap=$KEYMAP
	local insert_mode_style="%{$bg[green]$fg_bold[white]%} INSERT %{$reset_color%}"
	local normal_mode_style="%{$bg[blue]$fg_bold[white]%} NORMAL %{$reset_color%}"

	if [[ "$keymap" == "vicmd" ]]; then
		echo -n ${normal_mode_style}
		return
	fi
	if [[ $keymap =~ "(main|viins)" ]]; then
		echo -n ${insert_mode_style}
		return
	fi
	if [[ -z $keymap ]]; then
		echo -n ${insert_mode_style}
		return
	fi
	echo -n $keymap
}

hooks-add-hook zle_keymap_select_hook regen-prompt

#
function get-last-exit()
{
	LAST_EXIT_CODE=$?
}
hooks-add-hook precmd_hook get-last-exit

# Scroll when prompt get too close to bottom edge
function prompt-auto-scroll()
{
	if [[ "$TERM" = "linux" ]]; then
		return
	fi

	# check if there is a command in the stdin buffer
	# (as the get_cursor_pos will discard it)
	local buff=""
	while read -u0 -t -k char; do
		buff=${buff}${char}
	done
	if ! [ -z "$buff" ]; then
		# push it on the ZLE input stack
		print -z "${buff}"
	fi

	# Get the cursor position for the (new) current prompt
	get_cursor_pos

	if test $CURSOR_POS_ROW -gt $(( $LINES - 4 )); then
		echo $'\e[4S'	# scroll the terminal
		echo $'\e[6A'
	fi
}
hooks-add-hook precmd_hook prompt-auto-scroll


function segmt_battery
{
	#local battery='$(battery.lua percentage)%%'
	local bat_perc=$(cat /sys/class/power_supply/BAT0/capacity)
	local bat_status=$(cat /sys/class/power_supply/BAT0/status)

	# color
	if [[ $bat_perc < 10 ]]; then
		echo -n "%{$fg_bold[red]%}"
	else
		echo -n "%{$fg[green]%}"
	fi

	# status
	[[ "$bat_status" =~ "Charging" ]] && echo -n "+"

	[[ $bat_status =~ "Discharging" ]] && printf "-" # printf because we cannot echo "-"

	# percentage
	echo -n $bat_perc"%%"

	# reset color
	echo -n "%{$fg[default]%}"
}

function segmt_shlvl
{
	if [[ $SHLVL = 1 ]]; then
		return
	fi

	local shlvl='%L'
	local shlvlStyle="%{$fg_bold[red]%}$shlvl  %{$reset_color%}"

	echo -n "${shlvlStyle}"
}

local username='%n'
local usernameStyle="%{$fg[yellow]%}${username}%{$fg[default]%}"

local currDir='%2~'
local currDirStyle="%{$fg_bold[cyan]%}${currDir}%{$fg[default]%}"

local cmdSeparator="%%"
local cmdSeparatorStyle="%{$fg_bold[magenta]%}${cmdSeparator}%{$fg[default]%}"

## Prompt
##############################################
autoload -U promptinit && promptinit

PROMPT_LINE='$(segmt_shlvl)''$(segmt_battery)'" [${usernameStyle}] ${currDir} ▷ "
PROMPT_LINE_OLD='$(segmt_shlvl)'"%{$bg[black]%} ${currDirStyle} %{$bg[default]%} ${cmdSeparatorStyle} "




## RPROMPT
##############################################


RPROMPT_LINE='$(segmt_in_vim)''$(segmt_in_sudo)''$(segmt_git_branch)''$(segmt_vim_mode)'
RPROMPT_LINE_OLD='$(segmt_in_vim)''$(segmt_in_sudo)'

# set prompts hooks

function set-normal-prompts()
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



# Segment date
#----------------------------------------

function segmt_time()
{
	local currentTime=$(date "+%H:%M [%d/%m]")
	local currentTimeStyle=" ${currentTime} "
	echo -n ${currentTimeStyle}
}

# Segment variable debug
#----------------------------------------

function segmt_debug()
{
	local debugVar=$*
	local debugVarStyle="%{$bg[blue]%} DEBUG: ${debugVar} %{$bg[default]%}"
	echo ${debugVarStyle}
}



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
local statusline='$(segmt_vim_mode)'"${slResetColor}"'$(segmt_time)'"${slResetColor}"'$(segmt_in_sudo)'"${slResetColor}""  "'$(segmt_last_exit_code)'

#
#-------------------------------------------------------------

# The statusline container
local statuslineContainer="%{${_saveCursor}${_positionStatusbar}${initStatusline}${statusline}${_restoreCursor}%}"

## Reset Prompt every N seconds
##############################################

TMOUT=60

# This special function is run every $TMOUT seconds
TRAPALRM () {
	# Reset prompt only when we are not in complete mode
	if [[ "$WIDGET" != "expand-or-complete" ]]; then
		zle reset-prompt
	fi
}


#----------------------------------------------------------------------------------
# Misc
#----------------------------------------------------------------------------------


# remember recent directories (use with 'cdr')
#-------------------------------------------------------------
autoload -Uz chpwd_recent_dirs cdr
add-zsh-hook chpwd chpwd_recent_dirs # this add a function hook everytime the pwd change


# load ssh keys in the current shell
#-------------------------------------------------------------
function loadsshkeys
{
	eval `ssh-agent`
	ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`
}


#----------------------------------------------------------------------------------
# ZLE Widgets
#----------------------------------------------------------------------------------

# insert sudo at <bol>
function zwidget-insert-sudo ()
{
	local cursor=$CURSOR
	BUFFER="sudo $BUFFER"
	CURSOR=(( cursor + 5 ))
}
zle -N zwidget-insert-sudo

# ZLE Tests
function zwidget-zletest ()
{
	zle -M "TEST OK";
}
zle -N zwidget-zletest

# Git status
function zwidget-git-status
{
	if [[ -n $BUFFER ]]; then
		zle push-input
	fi
	BUFFER="git status"
	zle accept-line
}
zle -N zwidget-git-status

# Just do nothing
function do-nothing () {}
zle -N do-nothing

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

# TODO: better binds organization

# Alt-L => redraw prompt on-demand
bindkey "\M-l" reset-prompt

# Alt-S => Insert sudo at buffer beginning
bindkey "\M-s" zwidget-insert-sudo

# Menu key => do nothing
bindkey "[29~" do-nothing

# Git status
bindkey "\M-g" zwidget-git-status

# Who doesn't want home and end to work?
bindkey '\e[7~' beginning-of-line
bindkey '\e[8~' end-of-line

# Alt-T => zle test
bindkey -M vicmd "ô" zwidget-zletest
bindkey -M viins "\M-t" zwidget-zletest

autoload -U edit-command-line
zle -N edit-command-line

# Alt-E => edit line in $EDITOR
bindkey -M viins "\M-e" edit-command-line

# Ctrl-F => file fuzzy search
bindkey -M viins '^f' fzf-file-widget
bindkey -M vicmd '^f' fzf-file-widget

# backspace and ^h working even after
# returning from command mode
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# Rebind the insert key.  I really can't stand what it currently does.
bindkey '\e[2~' overwrite-mode

# Rebind the delete key. Again, useless.
bindkey '\e[3~' delete-char

bindkey -M viins '^p'  up-line-or-history
bindkey -M viins '^n'  down-line-or-history


# cut the buffer and push it on the buffer stack
bindkey -M vicmd '#' push-input
bindkey -M viins '\M-#' push-input


# menuselect keybindings
#-------------------------------------------------------------

# enable go back in completions with S-Tab
bindkey -M menuselect '[Z' reverse-menu-complete

# Cancel current completion with Esc
bindkey -M menuselect "" send-break

# Alt-hjkl to move inside results
bindkey -M menuselect "\M-h" backward-char
bindkey -M menuselect "\M-j" down-line-or-history
bindkey -M menuselect "\M-k" up-line-or-history
bindkey -M menuselect "\M-l" forward-char

# Alt-$ & Alt-0 => got to first & last results
bindkey -M menuselect "\M-0" beginning-of-line
bindkey -M menuselect "\M-$" end-of-line

. ~/.zsh/fzf/key-bindings.zsh

#----------------------------------------------------------------------------------
# Other init
#----------------------------------------------------------------------------------

# OPAM configuration
#----------------------------------------

[ -f ~/.opam/opam-init/init.zsh ] && . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true



