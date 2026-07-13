import subprocess
from typing import Any, Iterator, List, Union

from hlwm.events import RawEvent
from hlwm.tag import Tag


class Hlwm:
    @staticmethod
    def hc(*args, default=...):
        args_strs = [str(arg) for arg in args]
        cmd = ["herbstclient", "--no-newline", *args_strs]
        # print(f"<-> HC: {cmd}")
        proc = subprocess.run(
            cmd,
            capture_output=True,
            encoding="utf-8",
        )
        if proc.returncode and default is not ...:
            # There was an error, but we have a default value
            return default
        else:
            proc.check_returncode()  # Raise in case of error
        # TODO: errors should be handled somewhere or at least wrapped here?
        return proc.stdout

    @staticmethod
    def get_raw_event_stream() -> Iterator[RawEvent]:
        hc_idle = subprocess.Popen(
            ["herbstclient", "--idle"],
            stdout=subprocess.PIPE,
            universal_newlines=True,
        )
        for event_str in hc_idle.stdout:  # type: ignore[union-attr]
            yield RawEvent.from_event_str(event_str.strip())

    @staticmethod
    def get_tags(monitor: str) -> List[Tag]:
        tags_desc = Hlwm.hc("tag_status", str(monitor))
        tags_desc = tags_desc.strip("\t").split("\t")
        return [Tag.from_status_desc(idx, desc) for idx, desc in enumerate(tags_desc)]

    @staticmethod
    def get_focused_tag(monitor: str) -> Tag:
        """
        Get the focused tag on the given monitor.

        :param monitor: The monitor scope.
        :param foo_bar: hello
        :param other: hello
        :return: The focused tag

        :raises Exception: When no focused tag found (shouldn't happen..)
        """
        for tag in Hlwm.get_tags(monitor=monitor):
            if tag.state.focused:
                return tag
        # NOTE: Actually it's currently NOT unreachable, but very unlikely.
        #       When the current tag is marked as urgent, it is not marked as focused.
        raise Exception(f"UNREACHABLE: No focused tag found for monitor '{monitor}'")

    @staticmethod
    def rename_tag(tag: Tag, new_name: str) -> None:
        """
        Rename the given tag with a new name.

        :param tag: Tag to rename
        :param new_name: The new name to set
        """
        Hlwm.hc("rename", tag.name, new_name)

    @staticmethod
    def add_tag(tag_name: str) -> None:
        """
        Add a new tag

        :param tag_name: Name of the new tag to add
        """
        Hlwm.hc("add", tag_name)

    @staticmethod
    def use_tag(tag: Union[Tag, str]) -> None:
        if isinstance(tag, Tag):
            tag = tag.name
        Hlwm.hc("use", tag)

    @staticmethod
    def set_attr(attr: str, value: Any) -> None:
        Hlwm.hc("attr", attr, value)

    @staticmethod
    def get_attr(attr: str) -> str:
        return Hlwm.hc("attr", attr)
