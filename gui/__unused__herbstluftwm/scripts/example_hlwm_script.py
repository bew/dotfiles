#!/usr/bin/env python3

from hlwm import Hlwm
from hlwm.events import try_parse_builtin_event


def update_stuff():
    tags = Hlwm.get_tags(monitor="")
    print("--- All tags:")
    for tag in tags:
        print(f"  {tag}")


for raw_event in Hlwm.get_raw_event_stream():
    builtin_event = try_parse_builtin_event(raw_event)
    if builtin_event:
        print(f"Got builtin event: {builtin_event}")
    else:
        print(f"Got event: {raw_event}")
    if raw_event.name.startswith("tag_"):
        update_stuff()
