#!/usr/bin/env python3

# External binaries:
# - herbstclient

# Insert script dir in the module lookup path. This is necessary since the
# script will not be launched from its directory by polybar.
import os
import sys; sys.path.append(os.path.dirname(__file__))  # noqa: E702
from typing import Optional, Tuple

import hlwm
from hlwm import Hlwm

from bar_fmt import action_start, action_end


def print_now(text, **kwargs):
    print(text, flush=True, **kwargs)


def format_tag_label(tag: hlwm.Tag, client_count: int):
    begin = ""
    end = ""
    if tag.state.urgent:
        begin += "%{F#f00}"
        end = "%{F-}" + end
    elif tag.state.focused and tag.state.this_monitor:
        begin += "%{u#ff7043}"
        end = "%{-u}" + end
        # FIXME: these underline above doesn't seem to work anymore :/
        # (with version polybar 3.5.0)
        # DIRTY HACK until the underline is fixed
        begin += "%{F#ff7043}"
        end = "%{F-}" + end

    if client_count == 0:
        # NOTE: Focused tag is not visible anymore because the underline is broken
        #       This condition is tmp until the above 'fixme' is resolved
        if not tag.state.focused:
            begin += "%{F#555}"
            end = "%{F-}" + end

    return begin + "  " + tag.name + "  " + end


def try_get_client_count(tag: hlwm.Tag) -> Optional[int]:
    result = Hlwm.hc("attr", f"tags.{tag.index}.client_count", default=None)
    if result is None:
        return None
    return int(result)


def regen_polybar_tags_list():
    # FIXME: get the monitor where the bar is displayed
    # Asked on IRC how I can match xrandr's monitors with hlwm's monitors. Because the the polybars
    # are aware of the xrandr monitor name, and here I need hlwm's monitor...
    # https://matrix.to/#/!fZBUOpdqzSNJzCHHQV:libera.chat/$tmjfhofgHHUALQDXY9DgS1ff5zJzvL0U37IjhDEt97A
    tags = Hlwm.get_tags(monitor="")

    tags_with_client_count: Tuple[hlwm.Tag, Optional[int]] = [
        (tag, try_get_client_count(tag))
        for tag in tags
    ]
    # Remove tags with 'None' client_count, usually means the tag doesn't exist anymore.
    # (this race condition can happen when rapidly deleting tags)
    tags_with_client_count = filter(lambda t_c: t_c[1] is not None, tags_with_client_count)

    formatted_tags = [
        format_tag_label(tag, client_count)
        for tag, client_count in tags_with_client_count
    ]
    clickable_tags = [
        action_start(f"herbstclient use '{tag.name}'") + tag_fmt + action_end()
        for tag, tag_fmt in zip(tags, formatted_tags)
    ]
    return "".join(clickable_tags)


line = regen_polybar_tags_list()
print_now(line)

for raw_event in Hlwm.get_raw_event_stream():
    if raw_event.name.startswith("tag_"):
        line = regen_polybar_tags_list()
        print_now(line)
