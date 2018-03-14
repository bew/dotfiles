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

function debug
{
    echo $* >> /t/xinitrc_debug
}

debug
debug "xinitrc startup"
debug "---------------"
debug

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
#background_run unclutter

# Warmer screen temperature at night
background_run redshift-gtk

# Run the compositor
[ -f ~/.config/compton ] && run compton --config ~/.config/compton -b

# Find the session
debug "Session is $1"
case $1 in
    awesome)
        session_args+=(awesome)
        ;;
    hlwm|herbstluftwm)
        session_args+=(herbstluftwm)
        ;;
    i3|i3wm)
        session_args+=(i3)
        ;;
    bsp|bspwm)
        session_args+=(bspwm)
        ;;
    *)
        # No known session, try to run it as command
        session_args+=($1)
        ;;
esac

# Empty the shell level, so terminal emulators thinks they are the first one
# in the chain
export SHLVL=

# Run The WM
debug "Session args: ${session_args[*]}"
${session_args[*]} &
wm_pid=$!

# HANG POINT! wait for the WM, then end X (end of this script)
wait $wm_pid
