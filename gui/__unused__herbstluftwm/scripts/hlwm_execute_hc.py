#!/usr/bin/env python3

# External binaries:
# - yad
# - herbstclient

# Insert script dir in the module lookup path. This is necessary since the
# script will not be launched from its directory by polybar.
import os
import shlex
import subprocess
import sys; sys.path.append(os.path.dirname(__file__))  # noqa: E702

import yad_utils as yad
from hlwm import Hlwm


def print_cmd_output(cmd_line: str, output: str, success: bool):
    if success:
        mark = ("+++", "OK")
    else:
        mark = ("---", "FAILED")
    start = f"<<< {mark[0]} Execution: {mark[1]} (cmd: {cmd_line})"
    end = ">>>"
    if output:
        print(start)
        print(output)
        print(end)
    else:
        print(f"{start} {end}")


def main():
    big_title = "<big>Herbstclient command</big>"
    sub_title = "(without 'hc' prefix)"
    cmd_history = []
    while True:
        lines = [big_title, sub_title]
        for (old_cmd, success) in cmd_history:
            if success:
                color = "#008000"
            else:
                color = "#cc0000"
            lines.append(f"<span color='{color}'>{old_cmd}</span>")

        cmd_line = yad.ask_text(
            text="\n".join(lines),
            text_align="left",
            input_label="hc",
            extra_args=["--selectable-labels"]  # allow copy/paste of old cmds
        )
        if not cmd_line.strip():
            print("Command is empty, bye!")
            sys.exit(0)

        try:
            output = Hlwm.hc(*shlex.split(cmd_line.strip()))
        except subprocess.CalledProcessError as err:
            print_cmd_output(cmd_line, err.stdout, success=False)
            cmd_history.append((cmd_line, False))
        else:
            print_cmd_output(cmd_line, output, success=True)
            cmd_history.append((cmd_line, True))

    print("Done!")


if __name__ == "__main__":
    main()
