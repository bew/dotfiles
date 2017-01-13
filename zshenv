ruby_path=~/.gem/ruby/2.3.0/bin
luarocks_path=~/.luarocks/bin

typeset -U path
path=(~/.bin ~/soft-portable $luarocks_path /usr/local/go/bin $ruby_path $path)

export GOPATH=$HOME/gocode

export PAGER="most"

export EDITOR="nvim"
export VISUAL="$EDITOR"

export GIT_EDITOR="$EDITOR"

export RLWRAP_EDITOR="vim '+call cursor(%L,%C)'"
