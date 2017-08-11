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

# enable vim mode
bindkey -v
KEYTIMEOUT=1 # ESC timeout is: $KEYTIMEOUT * 10ms

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
# FIXME: if the read buffer is not empty, need to discard it
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
	zle && zle reset-prompt
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

function reload_zshrc
{
	if [ -n "$(jobs)" ]; then
		echo "Error: $(jobs | wc -l) job(s) in background"
	else
		exec zsh
	fi
}

alias zshrc=reload_zshrc

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

alias j=jobs

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

alias ls="ls --color --group-directories-first"
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

function mkcd()
{
	mkd $*
	cd $1
}

# for emacs users :p
alias ne="echo 'Use: vim'"

# tree

alias tree="tree -C --dirsfirst -F"

# cd

alias ..="cd ..;"
alias ...="cd ../..;"
alias ....="cd ../../..;"

# pacman

alias pacmanuseless="command sudo pacman -Rnsv \$(command sudo pacman -Qtdq)"


# sudo

# Makes sudo work with alias (e.g. 'sudo pac' => 'sudo pacman')
# Note: the trailing space is important (see the man for the alias builtin)
alias sudo="sudo "

# Close the current sudo session if any
alias nosudo="sudo -k;"


# history search
function hsearch()
{
	if test "$1" = ""; then
		history 1
	else
		history 1 | \grep --color=auto $1
	fi
}


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

alias view="vim -R -c 'set nomod nolist'"

alias ":h"="vimhelp"
alias ":q"="exit"

# man in vim
function man()
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

#

alias valgrindleak="valgrind --leak-check=full --show-reachable=yes"
alias cdgit='git rev-parse && cd "$(git rev-parse --show-toplevel)"'

alias makeawesome='make CMAKE_ARGS="-DLUA_LIBRARY=/usr/lib/liblua.so"'

# use ack instead !!
alias grep="echo Use ack"

# Hacks

# 'pezop' is a firefox profile, where the browser language is in french, to
# bypass language limitations on www.rotazu.com :)
alias ff_streaming="firefox -P pezop www.rotazu.com &!"


# Fast config edit

alias vimzshrc="vim ~/.zshrc"
alias vimnviminit="vim ~/.config/nvim/init.vim"


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

# Activate completion for AWS
if [ -f /usr/sbin/aws_zsh_completer.sh ]; then
	source /usr/sbin/aws_zsh_completer.sh
fi

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

zmodload zsh/system

# Scroll when prompt get too close to bottom edge
function prompt-auto-scroll()
{
	# Don't attempt to scroll in a tty
	if [[ "$TERM" = "linux" ]]; then
		return
	fi

	# check if there is a command in the stdin buffer
	# (as the get_cursor_pos will discard it)
	# FIXME: find how to turn on raw input
	local buff
	sysread -t 0.1 -i 0 buff
	#echo "Buff: '$buff'"
	if ! [ -z "$buff" ]; then
		# push it on the ZLE input stack
		print -z "${buff}"
	fi

	# Get the cursor position for the (new) current prompt
	get_cursor_pos

	if (( CURSOR_POS_ROW > (LINES - 4) )) then
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

	[[ $bat_status =~ "Discharging" ]] && printf "%s" "-" # printf because we cannot echo "-"

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

function zle::utils::check_git
{
	local error="Error:"
	if [ -n "$1" ]; then
		error="Error: $1 -"
	fi

	if ! in_a_git_repo; then
		zle -M "${error} Not a git repository"
		return 1
	fi
}

# insert sudo at <bol>
function zwidget-insert-sudo ()
{
	local cursor=$CURSOR
	BUFFER="sudo $BUFFER"
	CURSOR=$(( cursor + 5 ))
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
	zle::utils::check_git "git status" || return

	echo
	git status
	zle reset-prompt
}
zle -N zwidget-git-status

# Git log
function zwidget-git-log
{
	zle::utils::check_git "git log" || return

	git l
}
zle -N zwidget-git-log

function zwidget-fg
{
	[ -z "$(jobs)" ] && zle -M "No running jobs" && return

	eval fg
	zle reset-prompt
}
zle -N zwidget-fg

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

function vibindkey
{
	bindkey -M viins $@
	bindkey -M vicmd $@
}
compdef _bindkey vibindkey

. ~/.zsh/fzf/key-bindings.zsh

# TODO: better binds organization

# Alt-L => redraw prompt on-demand
bindkey 'l' reset-prompt

# Alt-S => Insert sudo at buffer beginning
vibindkey 's' zwidget-insert-sudo

# Menu key => do nothing
bindkey '[29~' do-nothing

# fast git
bindkey 'g' zwidget-git-status
bindkey 'l' zwidget-git-log

# Who doesn't want home and end to work?
bindkey '\e[7~' beginning-of-line
bindkey '\e[8~' end-of-line

# Alt-T => zle test
bindkey -M viins 't' zwidget-zletest

autoload -U edit-command-line
zle -N edit-command-line

# Alt-E => edit line in $EDITOR
bindkey -M viins 'e' edit-command-line

# Ctrl-F => file fuzzy search
vibindkey '^f' fzf-file-widget

# Ctrl-Z => fg
vibindkey '^z' zwidget-fg


# Alt-c => cd to directory with fuzzy search
vibindkey 'c' fzf-cd-widget

# Ctrl-R => history fuzzy search
#bindkey -M viins '^r' fzf-history-widget  # sorting is reversed :(

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
bindkey -M viins '#' push-input


# menuselect keybindings
#-------------------------------------------------------------

# enable go back in completions with S-Tab
bindkey -M menuselect '[Z' reverse-menu-complete

# Cancel current completion with Esc
bindkey -M menuselect '' send-break

# Alt-hjkl to move inside results
bindkey -M menuselect 'h' backward-char
bindkey -M menuselect 'j' down-line-or-history
bindkey -M menuselect 'k' up-line-or-history
bindkey -M menuselect 'l' forward-char

# Alt-$ & Alt-0 => got to first & last results
bindkey -M menuselect '0' beginning-of-line
bindkey -M menuselect '$' end-of-line

bindkey -M menuselect 'a' accept-and-hold

