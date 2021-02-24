#!/usr/bin/env python3

# External binaries:
# - herbstclient

# Insert script dir in the module lookup path. This is necessary since the
# script will not be launched from its directory by polybar.
import os
import sys; sys.path.append(os.path.dirname(__file__))  # noqa: E702

import hlwm
from hlwm import Hlwm


def print_now(text, **kwargs):
    print(text, flush=True, **kwargs)


def format_tag_label(tag: hlwm.Tag):
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

    client_count = int(Hlwm.hc("attr", f"tags.{tag.index}.client_count"))
    if client_count == 0:
        # NOTE: Focused tag is not visible anymore because the underline is broken
        #       This condition is tmp until the above 'fixme' is resolved
        if not tag.state.focused:
            begin += "%{F#555}"
            end = "%{F-}" + end

    return begin + "  " + tag.name + "  " + end


def regen_polybar_tags_list():
    tags = Hlwm.get_tags(monitor="")
    formatted_tags = [format_tag_label(tag) for tag in tags]
    clickable_tags = [
        "%{A1:herbstclient use '" + str(tag.name) + "':}" + tag_fmt + "%{A}"
        for tag, tag_fmt in zip(tags, formatted_tags)
    ]
    return "".join(clickable_tags)


line = regen_polybar_tags_list()
print_now(line)

for raw_event in Hlwm.get_raw_event_stream():
    if raw_event.name.startswith("tag_"):
        line = regen_polybar_tags_list()
        print_now(line)
