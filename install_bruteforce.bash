#!/usr/bin/env bash

function make-link
{
  local link_to="$1"
  local link_destination="$2"

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

DRYRUN_ONLY="false"
if [[ "$1" == "--dry-run" ]]; then
  DRYRUN_ONLY="true"
fi
DOTS_PATH=$(dirname $(realpath "$0"))

label "Bootstraping .dot symlinks"
make-link "$DOTS_PATH"  ~/.dot

label "bin links"
make-link ~/.dot/bin     ~/.bin
make-link ~/.dot/gui/bin ~/.bin-gui

label "zsh links"
skip make-link ~/.dot/zsh/zshrc   ~/.zshrc
skip make-link ~/.dot/zsh/zshenv  ~/.zshenv
make-link ~/.dot/zsh/zlogin  ~/.zlogin

label "nvim link"
skip make-link ~/.dot/nvim  ~/.config/nvim

label "git links"
make-link ~/.dot/git  ~/.config/git
make-link ~/.dot/gh   ~/.config/gh

label "Nix stuff"
make-link ~/.dot/nix/nix-self-config  ~/.config/nix

label "other cli tools"
make-link ~/.dot/htop            ~/.config/htop
make-link ~/.dot/tmux/tmux.conf  ~/.tmux.conf
make-link ~/.dot/gdb             ~/.config/gdb

label "X configs"
make-link ~/.dot/gui/xinitrc       ~/.xinitrc
make-link ~/.dot/gui/xprofile      ~/.xprofile
make-link ~/.dot/gui/xkbmap.config ~/.config/xkbmap.config
make-link ~/.dot/gui/picom.config  ~/.config/picom.config # compositor
make-link ~/.dot/gui/mimeapps.list ~/.config/mimeapps.list # xdg MIME type to apps associations
make-link ~/.dot/gui/autorandr     ~/.config/autorandr

label "X apps configs"
# terms
make-link ~/.dot/gui/wezterm   ~/.config/wezterm

# Desktop env
make-link ~/.dot/gui/herbstluftwm  ~/.config/herbstluftwm
make-link ~/.dot/gui/polybar       ~/.config/polybar
make-link ~/.dot/gui/dunst         ~/.config/dunst
make-link ~/.dot/gui/flameshot     ~/.config/flameshot
make-link ~/.dot/gui/copyq         ~/.config/copyq
make-link ~/.dot/gui/libinput-gestures.conf  ~/.config/libinput-gestures.conf

# tools
make-link ~/.dot/gui/mpv       ~/.config/mpv
make-link ~/.dot/gui/tridactyl ~/.config/tridactyl

# vscode (if I ever want to have it..)
if [[ -d ~/.config/"Code - OSS" ]]; then
  make-link ~/.dot/gui/vscode-user-config ~/.config/"Code - OSS"/User
fi

if [[ "$DRYRUN_ONLY" == "true" ]]; then
  echo
  echo "### To apply the above config, re-run without --dry-run"
  echo
fi
