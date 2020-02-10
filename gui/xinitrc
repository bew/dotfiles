#!/bin/sh

source ~/.xprofile

if [ -n "$SESSION" ]; then
    SESSION="$SESSION"
else
    SESSION="awesome"
fi

# Find the session
debug "Session is $SESSION"
case $SESSION in
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
        session_args+=($SESSION)
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
