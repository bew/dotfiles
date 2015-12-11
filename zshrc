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

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
unsetopt beep

bindkey -v







## auto completion
############################################################################################
autoload -U compinit && compinit

## menu completion style
##############################################
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors yes

# Case insensitive tab-completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Direct complete with the first completion
# I don't like : I cannot add letters once completion started
#setopt MENU_COMPLETE

zmodload zsh/complist

# enable go back in completions with S-Tab
bindkey -M menuselect '^[[Z' reverse-menu-complete

# Cancel current completion with Esc
bindkey -M menuselect "^[" send-break



# do not remove slash on directory completion
unsetopt AUTO_REMOVE_SLASH

# enable Completion in the middle of a word
setopt COMPLETE_IN_WORD

# after a middle word completion, move cursor at end of word
setopt ALWAYS_TO_END








#########################################
# ignore history duplications
setopt HIST_IGNORE_DUPS











################################################
# aliases
alias zshrc="source ~/.zshrc"

alias xt="xterm&"

alias grep="grep --color=auto -n"

alias ls="ls --color=auto --group-directories-first"
alias lsl="ls -lh"
alias ll="lsl"
alias la='lsl -a'
alias l="la"
alias ls1="ls -1"
alias clsl="clr && pwd && lsl"
alias j="jobs"

alias clr="clear"
alias pg="ping google.fr"
alias pgc="pg -c 1 -w 5"

alias cp="cp -v"
alias mv="mv -v"
alias mkd="mkdir -vp"

alias ne="echo 'Use: vim'"

alias tree="tree -C --dirsfirst -F"
alias tre="tree"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# pacman
alias pacman="sudo pacman"

## Remove useless packages
alias pacmanuseless="pacman -Rnsv \$(pacman -Qtdq)"


# Close the current sudo session if any
alias nosudo="sudo -k"


function mkcd()
{
	mkd $*
	cd $1
}

# google search
function gg()
{
	chromium "google.fr/#q=$1" 2> /dev/null
}

function hsearch()
{
	if test "$1" = ""; then
		history 1
	else
		history 1 | grep $1
	fi
}


##### VIM #####

alias vimlog="vim -X -V20/home/lesell_b/.vim/log/vimlog-\$(date +'%y-%m-%d_%H-%M')"
alias v="vim -X"
alias vm="v"
alias vi="v"
alias vim="v"
alias vmi="v"
alias imv="v"
alias ivm="v"


# vim for read only
alias view="vim -R -c 'set nomod nolist'"

# man in vim
function man()
{
	/usr/bin/man $* | col -bp | vim -R -c "set ft=man" -
}
# man completion
compdef _man man


####### ALIAS ########

function epiclone
{
	echo "$fg[blue]Cloning from git@git.epitech.eu:$fg[yellow]$*$reset_color"
	git clone git@git.epitech.eu:$*
}

alias make="make"
alias remake="make --silent fclean; make -j all > /dev/null; clean .o > /dev/null"
alias remkae="remake"
alias remaek="remake"

## norme check in recursive
alias nall="n $* \$(tree -if)"

alias cl="clean"

alias valgrindleak="valgrind --leak-check=full --show-reachable=yes"

alias zut="sudo !!"

########## GIT ##########
alias gti="git"
alias gitcheck="git checkout"
alias gitadl="git add --all"
alias gitai="git add -i"

alias gitstatus="git status"
alias gitstatusall="git status -u" # show all untracked files
alias gitdiff="git diff --word-diff=color --ignore-all-space"

alias gitbranch="git branch -vv"

alias gitlog="git log --graph --abbrev-commit --decorate --format=format:'%C(bold red)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%n' --all"

alias gitlogstat="gitlog --stat"

alias gitpush="git push"
alias gitpull="git pull"

alias push="gitpush"

###### CWD copy/paste ######
function cpwd ()
{
	echo \"$(pwd)\" copied into X primary clipboard;
	pwd | xclip -in -selection primary;
}

alias cdwd="cd \$(xclip -out -selection primary) && echo 'Moved to' \$(pwd)"


# Fast config edit
alias vimzshrc="vim ~/.zshrc"
alias vimvimrc="vim ~/.vimrc"


###########################################
# help
autoload -U run-help
autoload run-help-git
#unalias run-help
alias help=run-help






###########################################
# zsh syntax hightlighting
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# Enable highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# Override highlighter colors
ZSH_HIGHLIGHT_STYLES[default]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=009,standout
ZSH_HIGHLIGHT_STYLES[alias]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=cyan,bold
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


##############################################
# prompt configuration
autoload -U promptinit && promptinit
autoload -U colors && colors
setopt promptsubst

function precmd()
{
	LAST_EXIT_CODE=$?
}

#local battery='$(battery percentage_num)%%'
local battery='$(battery.lua percentage)%%'
local batteryStyle="%{$fg[green]%}${battery}%{$reset_color%}"

local username='%n'
local usernameStyle="%{$fg[yellow]%}${username}%{$reset_color%}"

local currDir='%2~'
local usrIsRoot='%(!.#.$)'


PROMPT="${batteryStyle} [${usernameStyle}] ${currDir} ${usrIsRoot}> "




## RPROMPT
#############################################################

# Widget git branch
#######################
source ~/.zsh/bin/git-prompt.sh

function widget_git_branch
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

# Widget last exit code
##########################
function widget_last_exit_code()
{
	if [[ $LAST_EXIT_CODE -ne 0 ]]; then
		local lastExitCodeStyle="%{$bg[black]$fg_bold[red]%} Last Exit: ${LAST_EXIT_CODE} %{$reset_color%}"
		echo -n ${lastExitCodeStyle}
	fi
}

# Widget shell in vim
#######################
function widget_in_vim
{
	if [[ $VIM != "" ]]; then
		echo -n " In Vim "
	fi
}

# Widget shell has sudo
########################
function widget_in_sudo
{
	local result=$(sudo -n echo -n bla 2>/dev/null)
	if test "$result" = "bla"; then
		local inSudo="In sudo"
		local inSudoStyle="%{$bg[red]$fg_bold[white]%} $inSudo %{$reset_color%}"
		echo $inSudoStyle
	fi
}

# Widget prompt vim mode
#########################
local vim_ins_mode_style="%{$bg[green]$fg_bold[white]%} INSERT %{$reset_color%}"
local vim_cmd_mode_style="%{$bg[blue]$fg_bold[white]%} NORMAL %{$reset_color%}"
local widget_vim_mode=$vim_ins_mode_style

function zle-keymap-select {
widget_vim_mode="${${KEYMAP/vicmd/${vim_cmd_mode_style}}/(main|viins)/${vim_ins_mode_style}}"
zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-finish {
widget_vim_mode=$vim_ins_mode_style
}
zle -N zle-line-finish

local rprompt='$(widget_in_vim)''$(widget_in_sudo)''$(widget_git_branch)''${widget_vim_mode}'

RPROMPT="${rprompt}"


# Widget date
###############

local currentTime='$(date "+%H:%M")'
local currentTimeStyle=" ${currentTime} "

# Widget variable debug
#########################"

local debugVar='' # add variables here to debug
local debugVarStyle="$bg[blue]${debugVar}"



## TODO: where to put theses ?
# useful ANSI codes
local _positionStatusbar=$'\e[$LINES;0H'
local _clearLine=$'\e[2K'
local _lineup=$'\e[1A'
local _linedown=$'\e[1B'
local _saveCursor=$'\e[s'
local _restoreCursor=$'\e[u'

## Widget Status line
########################################################################################


## StatusLine Config
######################

local slDefaultBG="$bg[magenta]"
local slDefaultFG=""


# TODO: list of widget for LeftStatusBar & RightStatusBar


local slResetColor="${reset_color}${slDefaultBG}${slDefaultFG}"

# statusline initializer
local initStatusline="${slResetColor}${_clearLine}"

#########################################################
#FIXME: YOU NEED TO CHANGE ONLY THIS LINE FIXME
# The statusline content
local statusline='${widget_vim_mode}'"${slResetColor}""${currentTimeStyle}""${slResetColor}""          "'$(widget_in_sudo)'"${slResetColor}""  ""${debugVarStyle}""${slResetColor}"'$(widget_last_exit_code)'
#########################################################

# The statusline container
local statuslineContainer="%{${_saveCursor}${_positionStatusbar}${initStatusline}${statusline}${_restoreCursor}%}"

# add statusline to prompt
PROMPT="${statuslineContainer}"$PROMPT


## Reset Prompt every N seconds
##############################################

TMOUT=60
#TMOUT=1    # every seconds !! (smooth on an i7 :P)

# This special function is run every $TMOUT seconds
TRAPALRM () {
	zle reset-prompt
}


## Misc
######################################################################################


# remember recent directories (use with 'cdr')
##############################################
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs # this add a function hook everytime the pwd change






# Add vim keys (ciw / ciW / etc...)
##############################################
source ~/.zsh/opp.zsh/opp.zsh





# load ssh keys in the current shell
##############################################
function loadsshkeys
{
	eval `ssh-agent`
	ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`
}
# Do it once at shell start
#loadsshkeys > /dev/null 2>&1





## Custom keybinds
##############################################

# Alt-L => redraw prompt on-demand
bindkey "ì" reset-prompt

