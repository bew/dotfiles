#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

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

xset -b # no beep

# Load all ssh keys
eval `ssh-agent`
ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`

# Hide mouse automatically
unclutter &

# Run the compositor
[ -f ~/.config/compton ] && compton --config ~/.config/compton -b

# Run the WM
exec awesome
