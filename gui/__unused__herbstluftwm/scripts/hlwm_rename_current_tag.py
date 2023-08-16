#!/usr/bin/env python3

# External binaries:
# - yad
# - herbstclient

# Insert script dir in the module lookup path. This is necessary since the
# script will not be launched from its directory by polybar.
import os
import sys; sys.path.append(os.path.dirname(__file__))  # noqa: E702

import yad_utils as yad
from hlwm import Hlwm


def main():
    focused_tag = Hlwm.get_focused_tag(monitor="")

    new_tag_name = yad.ask_text(
        text="<big>Rename tag</big>",
        input_label="Name:",
        prefill_text=focused_tag.name,
    )
    if not new_tag_name:
        print("Tag rename discarded, bye!")
        sys.exit(1)

    if new_tag_name == focused_tag.name:
        print("Tag didn't change, bye!")
        sys.exit(1)

    print(f"Renaming tag to '{new_tag_name}'")
    Hlwm.rename_tag(
        tag=focused_tag,
        new_name=new_tag_name
    )
    print("Done!")


if __name__ == "__main__":
    main()
