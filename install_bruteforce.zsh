#!/bin/zsh

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
make-link .config/dotfiles ~/.dot
make-link dotfiles         ~/.config/.dot

label "bin link"
make-link .dot/bin ~/.bin

label "zsh links"
make-link .dot/zsh     ~/.zsh
make-link .zsh/zshrc   ~/.zshrc
make-link .zsh/zshenv  ~/.zshenv
make-link .zsh/zlogin  ~/.zlogin

label "nvim links"
make-link .dot/nvim  ~/.config/nvim
make-link .dot/nvim  ~/.nvim # shortcut

label "git links"
make-link .dot/gitconfig ~/.gitconfig
make-link .dot/gitignore ~/.gitignore

label "Nix stuff"
make-link .dot/nixpkgs    ~/.config/nixpkgs

label "other cli tools"
make-link .dot/mostrc    ~/.mostrc
make-link .dot/gdbinit   ~/.gdbinit
make-link .dot/htop      ~/.config/htop
make-link .dot/tmux/tmux.conf ~/.tmux.conf

label "X configs"
make-link .dot/gui/xinitrc       ~/.xinitrc
make-link .dot/gui/xprofile      ~/.xprofile
make-link .dot/gui/xkbmap.config ~/.config/
make-link .dot/gui/Xresources    ~/.Xresources
make-link .dot/gui/Xresources.d  ~/.Xresources.d
make-link .dot/gui/picom.config  ~/.config/picom.config # compositor, old compton
make-link .dot/gui/mimeapps.list ~/.config/mimeapps.list # xdg default apps

label "X apps configs"
# terms
make-link .dot/gui/urxvt     ~/.urxvt
make-link .dot/gui/wezterm   ~/.config/wezterm
make-link .dot/gui/alacritty ~/.config/alacritty
make-link .dot/gui/kitty     ~/.config/kitty
make-link .dot/gui/dunst     ~/.config/dunst

# Desktop env
make-link .dot/gui/herbstluftwm ~/.config/herbstluftwm
make-link .dot/gui/libinput-gestures.conf ~/.config/libinput-gestures.conf
make-link .dot/gui/polybar ~/.config/polybar

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
