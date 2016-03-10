ruby_path=~/.gem/ruby/2.3.0/bin

typeset -U path
path=(~/.bin ~/soft-portable $path /usr/local/go/bin $ruby_path)

export GOPATH=$HOME/gocode

export PAGER="most"

export EDITOR="vim"
export VISUAL="$EDITOR"

export GIT_EDITOR="$EDITOR"

export RLWRAP_EDITOR="vim '+call cursor(%L,%C)'"
