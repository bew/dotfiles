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

[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap

setxkbmap -config ~/.config/xkbmap.config
[ -f ~/.Xresources ] && xrdb ~/.Xresources

xset -b # no beep
#xset -r # no auto key repeat

pulseaudio --start

eval `ssh-agent`
ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`

# hide mouse automatically
unclutter &

[ -f ~/.config/compton ] && compton --config ~/.config/compton -b

exec awesome
