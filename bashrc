#!/bin/bash

#TODO
export DUMP_PARTITION_PATH="/mnt/dump"

# init colors:
source ~/.bash/xcolors

######## EXPORTS #######

export PATH=$PATH":~/.bin:~/soft-portable"

#export GOPATH="/home/lesell_b/gocode"


#export SHELL='/bin/bash'
export EDITOR='vim'
export HISTSIZE=1000
export PAGER="most"
export SAVEHIST=1000
export WATCH='all'

source ~/.bash/common/common.bashrc

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




#if [ -f ${HOME}/.mybashrc ]
#then
#    . ${HOME}/.mybashrc
#fi

######### PS1 #########
source ~/.bash/PS1_gen

#### PS1 for ranger ####
[ -n "$RANGER_LEVEL" ] && PS1="<! "$PS1" !> "


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


