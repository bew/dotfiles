#!/bin/bash

# init colors:
source ${MYBIN_PATH}/bashrc/xcolors

######## EXPORTS #######

export PATH=$PATH":~/.bin:~/soft-portable"

#export GOPATH="/home/lesell_b/gocode"

export SHELL='/bin/bash'
export EDITOR='vim'
export HISTSIZE=1000
export PAGER="most"
export SAVEHIST=1000
export WATCH='all'

####### ALIAS ########

alias bashrc="source /home/lesell_b/.bashrc"

alias ls="ls --color=auto"
alias l="ls -la"
alias lsl="ls -l"
alias la='ls -la'
alias ls1="ls -1"
alias clsl="clr && pwd && lsl"
alias emacs='emacs -nw'
alias ne='emacs'
alias j="jobs"

alias clr="clear"
alias pg="ping google.fr"
alias pgc="pg -c 1 -w 5"
alias pi="ping intra.epitech.eu"
#alias wallp="wallpaper-service 30"

alias cp="cp -v"
alias mv="mv -v"
alias mkd="mkdir -vp"

alias make="make"
alias remake="make re > /dev/null && make clean > /dev/null && clean .o > /dev/null"
alias fcmake="make fclean"
alias cmake="make clean"

## norme check in recursive
#alias nall="n \$(tree -if)"

alias c="clean"
alias valgrind="valgrind --leak-check=full"

#alias cdmath="cd ~/rendu/Tek1_2014/Math"
#alias cdwork="cd ~/rendu/Tek1_2014"

######## GIT #########
alias glog="git log --graph"

## run java app
function run_java {
	if [[ -z $1 ]]; then
		echo "Usage: run_java <jar/file/path>"
		return
	fi
	wmname LG3D
	java -jar $1
}




if [ -f ${HOME}/.mybashrc ]
then
    . ${HOME}/.mybashrc
fi

######### PS1 #########
source ${MYBIN_PATH}/bashrc/PS1_gen

#### PS1 for ranger ####
#[ -n "$RANGER_LEVEL" ] && PS1="<! "$PS1" !> "


#======= Custom keybind =======#
# Alt + E	=>	launch 'ranger'
bind '"\ee": " ranger\n"'
# Alt + R	=>	reload bashrc config
bind '"\er": " bashrc\n"'
# Alt + C	=>	clr
bind '"\ec": " clr\n"'
# Alt + L	=>	lsl
bind '"\el": " lsl\n"'
# Alt + G	=>	pgc
bind '"\eg": " pgc\n"'


