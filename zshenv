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


# ------------------ fzf config

FZF_KEYBINDINGS=()

# input nav
FZF_KEYBINDINGS+=(--bind 'alt-h:backward-char' --bind 'alt-l:forward-char')
FZF_KEYBINDINGS+=(--bind 'alt-b:backward-word' --bind 'alt-w:forward-word')

# suggestions nav
FZF_KEYBINDINGS+=(--bind 'alt-j:down' --bind 'alt-k:up')
FZF_KEYBINDINGS+=(--bind 'tab:down' --bind 'shift-tab:up' --bind 'alt-g:jump')

# other
FZF_KEYBINDINGS+=(--bind 'ctrl-j:accept')
FZF_KEYBINDINGS+=(--bind 'alt-a:toggle+down')
FZF_KEYBINDINGS+=(--bind 'change:top') # select best result on input change

FZF_LAYOUT=(--height=40% --reverse --inline-info --border)

export FZF_BEW_KEYBINDINGS="${(j: :)${FZF_KEYBINDINGS}}"
export FZF_BEW_LAYOUT="${(j: :)${FZF_LAYOUT}}"
