#!/usr/bin/env python3

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
    if tag.state.focused and tag.state.this_monitor:
        begin += "%{u#ff7043}"
        end = "%{-u}" + end

    client_count = int(Hlwm.hc("attr", f"tags.{tag.index}.client_count"))
    if client_count == 0:
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
