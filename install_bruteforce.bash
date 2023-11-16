#!/usr/bin/env bash

function make-link
{
  local link_to="$1"
  local link_destination="$2"

  # When linking `src/bar` to `foo/`
  # $link_destination should be `foo/bar`
  #
  # NOTE: in bash, ${foo:(-N)} takes last N chars
  # Ref: https://stackoverflow.com/a/19858692
  if [[ "${link_destination:(-1)}" == "/" ]]; then
    link_destination="${link_destination}$(basename "$link_to")"
  fi

  local old_link_to="$(readlink "$link_destination" || true)"
  if [[ "$link_to" == "$old_link_to" ]]; then
    echo "nothing to do, '$link_destination' already points to '$link_to'"
    return
  fi

  if [[ "$DRYRUN_ONLY" == "true" ]]; then
    local before before_short
    if [[ -n "$old_link_to" ]]; then
      before_short=R
      before="was '$old_link_to'"
    else
      before_short=N
      before="to create"
    fi
    echo "DRYRUN[$before_short]: '$link_destination' -> '$link_to' ($before)"
  else
    ln -vsf --no-dereference "$link_to" "$link_destination"
  fi
}

function label
{
  echo
  echo "---- $1"
}

function skip
{
  echo "SKIPPED: $*"
}

# opt-in apply
DRYRUN_ONLY=true
if [[ "$1" == "--apply" ]]; then
  DRYRUN_ONLY=false
fi
DOTS_PATH=$(dirname $(realpath "$0"))

label "Bootstraping .dot symlinks"
make-link "$DOTS_PATH"  ~/.dot

label "bin links"
make-link ~/.dot/bin     ~/.bin
make-link ~/.dot/gui/bin ~/.bin-gui

skip label "shell links"
skip make-link ~/.dot/zsh/zshrc   ~/.zshrc
skip make-link ~/.dot/zsh/zshenv  ~/.zshenv
skip make-link ~/.dot/zsh/zlogin  ~/.zlogin
make-link ~/.dot/nushell  ~/.config/nushell

skip label "nvim link"
skip make-link ~/.dot/nvim  ~/.config/nvim

label "git links"
make-link ~/.dot/git  ~/.config/git
make-link ~/.dot/gh   ~/.config/gh

label "Nix stuff"
make-link ~/.dot/nix/nix-self-config  ~/.config/nix

label "other cli tools"
make-link ~/.dot/gui/htop        ~/.config/htop
make-link ~/.dot/tmux/tmux.conf  ~/.tmux.conf
make-link ~/.dot/gdb             ~/.config/gdb

mkdir -vp ~/.ipython/profile_default/startup
make-link ~/.dot/ipy-startup/00-custom-config.py ~/.ipython/profile_default/startup/

label "X apps configs"
# terms
make-link ~/.dot/gui/wezterm   ~/.config/wezterm

# Desktop env
make-link ~/.dot/gui/dunst         ~/.config/dunst
make-link ~/.dot/gui/flameshot     ~/.config/flameshot
make-link ~/.dot/gui/copyq         ~/.config/copyq

# tools
make-link ~/.dot/gui/tridactyl ~/.config/tridactyl

# vscode (if I ever want to have it..)
if [[ -d ~/.config/"Code - OSS" ]]; then
  make-link ~/.dot/gui/vscode-user-config ~/.config/"Code - OSS"/User
fi

if $DRYRUN_ONLY; then
  echo
  echo "### To apply the above config, re-run with '--apply"
  echo
fi
