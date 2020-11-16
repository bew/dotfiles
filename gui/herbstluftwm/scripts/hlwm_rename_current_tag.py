#!/usr/bin/env python3

# External binaries:
# - yad
# - herbstclient

# Insert script dir in the module lookup path. This is necessary since the
# script will not be launched from its directory by polybar.
import os
import sys; sys.path.append(os.path.dirname(__file__))  # noqa: E702

from typing import Optional
import subprocess

from hlwm import Hlwm


def ask_text(prefill_text: Optional[str]) -> str:
    cmd = [
        "yad",
        "--on-top",
        "--center",
        "--close-on-unfocus",
        "--entry",
    ]
    if prefill_text:
        cmd += ["--entry-text", prefill_text]
    proc = subprocess.run(
        args=cmd,
        capture_output=True,
        encoding="utf-8",
    )
    return proc.stdout.strip("\n")


def main():
    focused_tag = Hlwm.get_focused_tag(monitor="")

    new_tag_name = ask_text(prefill_text=focused_tag.name)
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
