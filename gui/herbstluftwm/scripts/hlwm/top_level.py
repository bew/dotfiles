import subprocess

from hlwm.events import RawEvent
from hlwm.tag import Tag


class Hlwm:
    @staticmethod
    def hc(*args: str):
        proc = subprocess.run(
            ("herbstclient", "--no-newline") + args,
            capture_output=True,
            encoding="utf-8",
        )
        proc.check_returncode()  # Raise in case of error
        # TODO: errors should be handled somewhere or at least wrapped here?
        return proc.stdout

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

    @staticmethod
    def get_focused_tag(monitor: str) -> Tag:
        for tag in Hlwm.get_tags(monitor=monitor):
            if tag.state.focused:
                return tag
        # NOTE: Actually it's currently NOT unreachable, but very unlikely.
        #       When the current tag is marked as urgent, it is not marked as focused.
        raise Exception(f"UNREACHABLE: No focused tag found for monitor '{monitor}'")

    @staticmethod
    def rename_tag(tag: Tag, new_name):
        Hlwm.hc("rename", tag.name, new_name)
