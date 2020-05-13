#-------------------------------------------------------------
# 

function _cmd_available
{
  command -v "$1" >/dev/null
}

function reload_zsh
{
  if [ -n "$(jobs)" ]; then
    print -P "Error: %j job(s) in background"
  else
    [[ -n "$ORIGINAL_PATH" ]] && export PATH="$ORIGINAL_PATH"
    exec zsh
  fi
}

alias zshrc=reload_zsh

# global aliases

alias -g noout=" >/dev/null "
alias -g noerr=" 2>/dev/null "

# Shorters

alias g=git
alias gh=hub
alias m=make
alias dk=docker
alias dkc=docker-compose
alias cr=crystal
alias pac=pacman
alias tre=tree
alias py=python
alias ipy=ipython
alias com=command
alias j=jobs

# Big-one letter aliases

alias A=ack
alias H=head
alias T=tail
alias L=less
alias V=vim
alias G="command grep --color=auto -n"

# Add verbosity to common commands

alias rm="rm -vI"
alias cp="cp -vi"
alias mv="mv -vi"
alias ln="ln -iv"
alias mkdir="mkdir -v"

# ls

alias ls="ls --color=auto --group-directories-first"
alias ll="ls -lh"
alias la="ll -a"
alias l="la"
alias l1="ls -1"

# curl

alias dl_file="curl -L -O"
alias curl_json='curl -H "Accept:application/json" -H "Content-Type:application/json"'

function curl_auth
{
  local token="$1"; shift
  if [[ -z "$token" ]]; then
    echo 2>/dev/null "Missing <token>"
    return 1
  fi

  curl -H "Authorization: Bearer $token" "$@"
}

function curl_auth_json
{
  local token="$1"; shift
  if [[ -z "$token" ]]; then
    echo 2>/dev/null "Missing <token>"
    return 1
  fi

  curl_auth "$token" -H "Accept:application/json" -H "Content-Type:application/json" "$@"
}

# misc

alias todo='rg -i "todo|fixme" --colors=match:fg:yellow --colors=match:style:bold'

function cheatsh
{
  curl cht.sh/$1
}

# ps
# -f : full listing (show process name & args)
# --forest : Show a processes hierarchy
alias pss="ps -f --forest"

# Colorful diffs (https://www.colordiff.org/)
if _cmd_available colordiff; then
  alias diff="colordiff"
fi

# ping
if _cmd_available prettyping; then
  alias pg="prettyping google.fr"
else
  alias pg="ping google.fr"
fi

# DNS lookup (`dig` is deprecated on archlinux)
if _cmd_available drill; then
  alias dig=drill
fi

# mkdir

alias mkd="mkdir -p"

# Creates 1 or more directories, then cd into the first one
function mkcd
{
    mkd "$@"
    cd "$1"
}

# tree

alias tree="tree -C --dirsfirst -F"

# cd

alias ..="cd ..;"
alias ...="cd ../..;"
alias ....="cd ../../..;"

alias cdt="cd /tmp;"

# pacman

alias pac::list_useless_deps="pacman -Qtdq"

function pac::show_useless_deps
{
    for package in $(pac::list_useless_deps); do
        echo "Package: $package"
        pacman -Qi $package | grep 'Description'
        echo
    done
}

alias pac::remove_useless_deps="command sudo pacman -Rsv \$(pac::list_useless_deps)"

# yay

alias yay="yay --builddir ~/.long_term_cache/yay_build_dir"

# git

alias gnp="git --no-pager"
alias git::status_in_all_repos="find -name .git -prune -print -execdir git status \;"
alias git_watch="watch --color -- git --no-pager -c color.ui=always"
alias cdgit='git rev-parse && cd "$(git rev-parse --show-toplevel)"'

# Clone git repository and cd to it
#
# Handles the following invocations:
# - gclonecd <url>
# - gclonecd <url>.git
# - gclonecd <url>      destination_dir
# - gclonecd <url>.git  destination_dir
function gclonecd
{
  local clone_dir
  if [[ -n "$2" ]] && ! [[ "$2" =~ "-" ]]; then
    clone_dir="$2"
  else
    # basename of url, removing '.git' if present
    clone_dir=$(basename "$1" .git)
  fi
  git clone "$@" && cd "$clone_dir"
}

# Open git viewer in nvim
# (https://github.com/junegunn/gv.vim)
alias gv="e +GV"

# sudo

# Makes sudo work with alias (e.g. 'sudo pac' => 'sudo pacman')
# Note: the trailing space is important (see the man for the zsh alias builtin)
alias sudo="sudo "

# Close the current sudo session if any
alias nosudo="sudo -k;"


# nvim

# launch editor (- let's try that!)
alias e="nvim"
alias er="nvim -R"

alias clean_swaps='rm ~/.nvim/swap_undo/swapfiles/.* ~/.nvim/swap_undo/swapfiles/*'

alias ":q"="exit"

# ncdu
alias ncdu='ncdu --color dark'

# ssh
alias ssh-password-only='ssh -o PubkeyAuthentication=no'

# nix
alias nix-prefetch-url-tarball='nix-prefetch-url --unpack'

# Media commands

# youtube-dl

alias ytdl='youtube-dl'
alias ytdl-m4a='ytdl --extract-audio -f m4a --ignore-errors'
alias ytdl-m4a-nolist='ytdl-m4a --no-playlist'

# mpv

alias mpv-audio='mpv --no-video'
alias mpv-audio-loop='mpv-audio --loop-playlist'

# ffmpeg

alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'


# clock in terminal

alias clock='tty-clock -sc -C6 -d 0.5'
alias c=clock

# text translation (with https://github.com/soimort/translate-shell)

# translation
alias fr:en='trans fr:en -b'
alias en:fr='trans en:fr -b'
function fr:en:fr
{
  local fr_en="$(fr:en $*)" && echo "en: $fr_en" && en:fr "$fr_en"
}
function en:fr:en
{
  local en_fr="$(en:fr $*)" && echo "fr: $en_fr" && fr:en "$en_fr"
}

# definition
alias en:def='trans en: -d'
alias fr:def='trans fr: -d'

# misc

alias makeawesome='make CMAKE_ARGS="-DLUA_LIBRARY=/usr/lib/liblua.so"'

# Hacks

# 'pezop' is a firefox profile, where the browser language is in french, to
# bypass language limitations on some sites :)
alias ff_streaming="firefox -P pezop www.diagrim.com &!"


# Fast config edit

alias ezshrc="e ~/.dot/zsh/zshrc"
alias enviminit="e ~/.dot/nvim/init.vim"
alias envimmappings="e ~/.dot/nvim/mappings.vim"
alias cddot="cd ~/.dot"
alias cdzsh="cd ~/.dot/zsh"
alias cdnvim="cd ~/.dot/nvim"
alias cdbin="cd ~/.dot/bin"

