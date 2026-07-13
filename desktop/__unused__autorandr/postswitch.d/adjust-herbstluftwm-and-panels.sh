#!/usr/bin/env bash

# Example env vars:
#   AUTORANDR_MONITORS=DP-1:eDP-1
#   AUTORANDR_CURRENT_PROFILE=home-dual
#   AUTORANDR_PROFILE_FOLDER=/home/user/.config/autorandr/home-dual

echo "> Notify!"
notify-send -i display "Display profile selected" "$AUTORANDR_CURRENT_PROFILE"

echo "> hlwm: detect_monitors"
herbstclient detect_monitors

echo "> panels kill & start again"
nohup desktop--restart-panels >/dev/null 2>&1 &

# TODO(later): Instead, send an event to my desktop system to adjust to the new set of screens
# With an event like:
#   adjust-to-screens profile:<PROFILE> <PRIMARY_SCREEN> [<SCREEN>...]
# E.g:
#   adjust-to-screens profile:home-dual eDP-1 DP-1
