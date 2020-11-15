import subprocess

from hlwm.events import RawEvent
from hlwm.tag import Tag


class Hlwm:
    @staticmethod
    def hc(*args):
        proc = subprocess.run(
            ("herbstclient", "--no-newline") + args,
            capture_output=True
        )
        proc.check_returncode()  # Raise in case of error
        # TODO: errors should be handled somewhere or at least wrapped here?
        return proc.stdout.decode("utf-8")

    @staticmethod
    def get_raw_event_stream():
        hc_idle = subprocess.Popen(
            ["herbstclient", "--idle"],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        for event_str in hc_idle.stdout:
            yield RawEvent.from_event_str(event_str.strip())

    @staticmethod
    def get_tags(monitor: str):
        tags_desc = Hlwm.hc("tag_status", str(monitor))
        tags_desc = tags_desc.strip("\t").split("\t")
        return [Tag.from_desc(idx, desc) for idx, desc in enumerate(tags_desc)]
