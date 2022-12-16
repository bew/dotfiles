#!/usr/bin/env bash

# Solves error "desktop effects were restarted due to a graphics reset" (when I get a constant stream of notification with this error, usually after getting back from suspend mode.
#
# Ref: https://www.reddit.com/r/ManjaroLinux/comments/mo0tma/desktop_effects_were_restarted_due_to_a_graphics/

nohup kwin_x11 --replace &
