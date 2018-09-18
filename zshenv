typeset -a OTHER_PATHS

function load_other_paths
{
    # User bins
    local user_bins=~/.bin

    # OSX bins
    local osx_bin_path=/usr/local/bin

    # Ruby bins
    local rvm_bin_path=~/.rvm/bin
    local ruby_bin_path=~/.gem/ruby/2.5.0/bin

    # Lua bins
    local luarocks_path=~/.luarocks/bin

    # adb & fastboot PATH, installed using install.sh script at
    # https://github.com/corbindavenport/nexus-tools
    local nexustools_bin_path=~/.nexustools

    # Python bins
    local python_bin_path=~/.local/bin

    OTHER_PATHS=(
        $user_bins
        $luarocks_path
        $python_bin_path
        $nexustools_bin_path
        $osx_bin_path
        $rvm_bin_path
        $ruby_bin_path
    )
}
load_other_paths

typeset -U path
path=(
    "${OTHER_PATHS[@]}" # Expand all other paths by elements
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

export FZF_BEW_KEYBINDINGS="${(j: :)FZF_KEYBINDINGS}"
export FZF_BEW_LAYOUT="${(j: :)FZF_LAYOUT}"

# ------------------ load local per-machine config

[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
