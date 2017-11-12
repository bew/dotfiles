# Ruby bins
ruby_path=~/.gem/ruby/2.3.0/bin

# Lua bins
luarocks_path=~/.luarocks/bin

# adb & fastboot PATH, installed using install.sh script at
# https://github.com/corbindavenport/nexus-tools
nexustools_path=~/.nexustools

# Python bins
python_path=~/.local/bin

typeset -U path
path=(
  ~/.bin
  $luarocks_path
  $ruby_path
  $python_path
  $nexustools_path
  $path
)

export GOPATH=$HOME/gocode

export PAGER="most"

export EDITOR="nvim"
export VISUAL="$EDITOR"

export GIT_EDITOR="$EDITOR"

SAVEHIST=1000000 # in history file
HISTSIZE=10000   # in session
