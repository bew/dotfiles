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







##############################################
# auto completion
autoload -U compinit && compinit

##############################################
# menu completion style
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors yes

zmodload zsh/complist
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey -M menuselect "^[" send-break












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

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias cpwd="pwd | xclip -in -selection primary; echo 'pwd copied in X clipboard'"

# Use the vim Man plugin
#alias man=viman

alias pacman="sudo pacman"

function mkcd()
{
	mkd $1
	cd $1
}

# google search
function gg()
{
	chromium "`echo "google.fr/#q="$1`"
}



# work specific aliases

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
alias nall="n \$(tree -if)"

alias cl="clean"
alias valgrind="valgrind --leak-check=full --show-reachable=yes"

alias cdmath="cd ${renduDir}/Tek1_2014/Math"
alias cdwork="cd ${renduDir}/Tek1_2014"

alias zut="sudo \`fc -ln -1\`"

########## GIT ##########
alias gitcheck="git checkout"
alias gitadl="git add --all"
alias gitai="git add -i"
alias gitacommit="gitadl && git commit"
alias gitstatus="git status"



######## LOL aliases #####################
alias lool="python -c 'print(\"blablablablablablablablablablablablablablablablablablablablablablablalablablablalablablablablabla\n\" * 500)'|lolcat"
alias loool="python -c 'print(\"blblablablablablablablablablablablablablablablablablablablablablablablablablablalablablablalablablablablablablablablablablablablablablablablablablablablablablablablablablablablalablablablalablablablablabla\n\" * 500)'|lolcat"



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

#local battery='$(battery percentage_num)%%'
local battery='$(battery.lua percentage)%%'
local batteryStyle="%{$fg[green]%}${battery}%{$reset_color%}"

local username='%n'
local usernameStyle="%{$fg[yellow]%}${username}%{$reset_color%}"

local currDir='%1~'
local usrIsRoot='%(!.#.$)'


PROMPT="${batteryStyle} [${usernameStyle}] ${currDir} ${usrIsRoot}> "




#>-- Git Branch on RPROMPT
source ~/.zsh/bin/git-prompt.sh

function my_rprompt
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

function in_vim
{
	if [[ $VIM != "" ]]; then
		echo -n "In Vim"
	fi
}

local rprompt='$(in_vim) $(my_rprompt)'

RPROMPT="${rprompt}"







##############################################
# remember recent directories (use with 'cdr')
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs # this add a function hook everytime the pwd change






##############################################
# widgets:
zle-keymap-select () {
  RPROMPT=$KEYMAP;
}
#zle -N zle-keymap-select;



##############################################
# Add the ciw and ciW and others vim word def:
source ~/.zsh/opp.zsh/opp.plugin.zsh





##############################################
# load ssh keys in the current shell
function load_sshkeys
{
  eval `ssh-agent`
  ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`
}
