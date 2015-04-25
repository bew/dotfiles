#!/bin/bash
# Commons bash alias

#temp
alias workBashRC="source ~/.bash/work/work.bashrc"

####### ALIAS ########

alias bashrc="source /home/lesell_b/.bashrc"

alias ls="ls --color=auto"
alias lsl="ls -lh"
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
alias cpwd="pwd | xclip -in -selection primary; echo 'pwd copied in X clipboard'"
