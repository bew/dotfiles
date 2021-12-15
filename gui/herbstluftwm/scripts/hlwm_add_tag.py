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


def main():
    focused_tag = Hlwm.get_focused_tag(monitor="")
    tags = Hlwm.get_tags(monitor="")
    tag_names = [tag.name for tag in tags]

    new_tag_name = f"new{randint(0, 99)}"
    big_text = "<big>Add tag</big>"
    error_msg = None
    while True:
        new_tag_name = yad.ask_text(
            text=(big_text if not error_msg else f"{big_text}\n{error_msg}"),
            input_label="Name:",
            prefill_text=new_tag_name,
        )
        if not new_tag_name:
            print("Tag add discarded, bye!")
            sys.exit(1)
        if new_tag_name in tag_names:
            print("Tag name already used, try another..")
            error_msg = "!! Name already used !!"
            continue
        if "." in new_tag_name:
            print("Invalid char '.' in name")
            error_msg = "!! Inavlid char '.' !!"
            continue
        break

    print(f"Adding tag '{new_tag_name}'")
    Hlwm.add_tag(new_tag_name)

    new_tag_index = focused_tag.index + 1
    print(f"Moving new tag on the right of current tag (-> idx: {new_tag_index})")
    Hlwm.set_attr(f"tags.by-name.{new_tag_name}.index", new_tag_index)

    print("Use the new tag")
    Hlwm.use_tag(new_tag_name)

    print("Done!")


if __name__ == "__main__":
    main()
