from dataclasses import dataclass
from typing import Optional


@dataclass
class TagState:
    # NOTE: Tag status is not always accurate, fields are optional when we
    # don't know..
    # For example `tag_status` cmd can tell when a tag has an urgent
    # window, but then we don't know if the tag is in a monitor and
    # if it is visible.

    #: the tag is empty
    empty: Optional[bool] = None

    #: the tag is visible (in a monitor)
    visible: Optional[bool] = None

    #: the tag is focused (in the focused monitor)
    focused: Optional[bool] = None

    #: the tag is on the monitor specified for the `tag_status` cmd
    this_monitor: bool = False

    #: the tag has an urgent window
    urgent: bool = False

    def __str__(self):
        active_states = []
        if self.empty:
            active_states.append("empty")
        if self.visible:
            active_states.append("visible")
        if self.focused:
            active_states.append("focused")
        if self.this_monitor:
            active_states.append("this_monitor")
        if self.urgent:
            active_states.append("urgent")
        return " ".join(active_states)


class Tag:
    STATE_FOR_STATUS_CHAR = {
        ".": TagState(empty=True, visible=False),
        ":": TagState(empty=False, visible=False),

        "+": TagState(visible=True, this_monitor=True),
        "#": TagState(visible=True, focused=True, this_monitor=True),
        "-": TagState(visible=True, this_monitor=False),
        "%": TagState(visible=True, focused=True, this_monitor=False),
        "!": TagState(urgent=True),
    }
    UNKNOWN_STATE = TagState()

    @classmethod
    def from_desc(cls, index, tag_desc):
        status_char = tag_desc[0]
        tag_name = tag_desc[1:]
        state = cls.STATE_FOR_STATUS_CHAR.get(status_char, cls.UNKNOWN_STATE)
        return cls(
            index=index,
            name=tag_name,
            state=state
        )

    def __init__(self, index: int, name: str, state: TagState):
        self.index = index
        self.name = name
        self.state = state

    def __str__(self):
        return (f"<Tag index={self.index} name='{self.name}' "
                f"state='{self.state}'>")

    # def get_attr(self, attr_name) -> str:
    #     # FIXME: cannot import Hlwm here, circular imports!
    #     return Hlwm.hc("attr", f"tags.{self.index}.{attr_name}")
