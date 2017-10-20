#!/bin/sh

# Run the program in background if it exists
function background_run
{
    which $1 >/dev/null && $* &
}

# Run the program if it exists
function run
{
    which $1 >/dev/null && $*
}

if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/*; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Setup keyboard mapping
[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap
setxkbmap -config ~/.config/xkbmap.config

# Setup X resources
[ -f ~/.Xresources ] && xrdb ~/.Xresources

# no beep
xset -b

# Load all ssh keys
eval `ssh-agent`
ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`

# Hide mouse automatically
background_run unclutter

# Warmer screen temperature at night
background_run redshift-gtk

# Run the compositor
[ -f ~/.config/compton ] && run compton --config ~/.config/compton -b

# Run the WM
exec awesome
