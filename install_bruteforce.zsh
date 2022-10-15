#!/usr/bin/env bash

function make-link
{
  if [[ "$DRYRUN_ONLY" == "true" ]]; then
    echo "DRYRUN: '$2' -> '$1'"
  else
    ln -vsf --no-dereference "$1" "$2"
  fi
}

function label
{
  echo
  echo "---- $1"
}

DRYRUN_ONLY="false"
if [[ "$1" == "--dry-run" ]]; then
  DRYRUN_ONLY="true"
fi

# Making sure the dotfiles are cloned to .config/dotfiles
if ! [[ -d ~/.config/dotfiles ]]; then
  echo "AAARGH: the dotfiles must be cloned to ~/.config/dotfiles"
  exit 1
fi

label "Bootstraping .dot symlinks"
make-link .config/dotfiles  ~/.dot
make-link dotfiles          ~/.config/.dot

label "bin links"
make-link .dot/bin     ~/.bin
make-link .dot/gui/bin ~/.bin-gui

label "zsh links"
make-link .dot/zsh/zshrc   ~/.zshrc
make-link .dot/zsh/zshenv  ~/.zshenv
make-link .dot/zsh/zlogin  ~/.zlogin

label "nvim link"
make-link .dot/nvim  ~/.config/nvim

label "git links"
make-link .dot/git  ~/.config/git
make-link .dot/gh   ~/.config/gh

label "Nix stuff"
make-link .dot/nix/nix-self-config  ~/.config/nix

label "other cli tools"
make-link .dot/htop            ~/.config/htop
make-link .dot/tmux/tmux.conf  ~/.tmux.conf
make-link .dot/gdb/gdbinit     ~/.config/gdb/gdbinit

label "X configs"
make-link .dot/gui/xinitrc       ~/.xinitrc
make-link .dot/gui/xprofile      ~/.xprofile
make-link .dot/gui/xkbmap.config ~/.config/xkbmap.config
make-link .dot/gui/Xresources    ~/.Xresources # FIXME: remove?
make-link .dot/gui/picom.config  ~/.config/picom.config # compositor
make-link .dot/gui/mimeapps.list ~/.config/mimeapps.list # xdg MIME type to apps associations
make-link .dot/gui/autorandr     ~/.config/autorandr

label "X apps configs"
# terms
make-link .dot/gui/wezterm   ~/.config/wezterm
make-link .dot/gui/alacritty ~/.config/alacritty

# Desktop env
make-link .dot/gui/herbstluftwm  ~/.config/herbstluftwm
make-link .dot/gui/polybar       ~/.config/polybar
make-link .dot/gui/dunst         ~/.config/dunst
make-link .dot/gui/flameshot     ~/.config/flameshot
make-link .dot/gui/copyq         ~/.config/copyq
make-link .dot/gui/libinput-gestures.conf  ~/.config/libinput-gestures.conf

# tools
make-link .dot/gui/mpv       ~/.config/mpv
make-link .dot/gui/tridactyl ~/.config/tridactyl

# vscode (if I ever want to have it..)
if [[ -d ~/.config/"Code - OSS" ]]; then
  make-link ~/.dot/gui/vscode-user-config ~/.config/"Code - OSS"/User
fi

if [[ "$DRYRUN_ONLY" == "true" ]]; then
  echo
  echo "### To apply the above config, re-run without --dry-run"
  echo
fi
