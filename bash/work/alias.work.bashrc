#!/bin/bash
# work specific aliases

####### ALIAS ########

alias make="make"
alias remake="make re > /dev/null && make clean > /dev/null && clean .o > /dev/null"
alias fcmake="make fclean"
alias cmake="make clean"

## norme check in recursive
alias nall="n \$(tree -if)"

alias c="clean"
alias valgrind="valgrind --leak-check=full --show-reachable=yes"

alias cdmath="cd ${renduDir}/Tek1_2014/Math"
alias cdwork="cd ${renduDir}/Tek1_2014"
