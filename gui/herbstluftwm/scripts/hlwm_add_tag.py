#!/usr/bin/env python3

# External binaries:
# - yad
# - herbstclient

# Insert script dir in the module lookup path. This is necessary since the
# script will not be launched from its directory by polybar.
import os
import sys; sys.path.append(os.path.dirname(__file__))  # noqa: E702
from random import randint

import yad_utils as yad
from hlwm import Hlwm

def generate_usused_tag_name() -> str:
    existing_tags = Hlwm.get_tags(monitor="")
    tag_names = [tag.name for tag in existing_tags]

    while (name := f"new{randint(0, 99)}") in tag_names:
        continue
    return name

def main():
    new_tag = generate_usused_tag_name()

    print(f"Adding tag '{new_tag}'")
    Hlwm.add_tag(new_tag)

    focused_tag = Hlwm.get_focused_tag(monitor="")
    new_tag_index = focused_tag.index + 1
    print(f"Moving new tag on the right of current tag (-> idx: {new_tag_index})")
    Hlwm.set_attr(f"tags.by-name.{new_tag}.index", new_tag_index)

    print("Use the new tag")
    Hlwm.use_tag(new_tag)


if __name__ == "__main__":
    main()
