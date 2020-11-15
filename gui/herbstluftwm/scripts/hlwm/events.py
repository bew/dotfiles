import abc
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class RawEvent:
    name: str
    args: List[str]

    @classmethod
    def from_event_str(cls, event_str: str):
        parts = event_str.split("\t")
        return cls(
            name=parts[0],
            args=parts[1:]
        )


class BaseEvent(abc.ABC):
    def __init__(self, raw_event: RawEvent, min_args: int):
        self.raw_event = raw_event
        self.name = raw_event.name
        if len(raw_event.args) < min_args:
            raise (f"Invalid event, expected at least {min_args} args, "
                   f"got {len(raw_event.args)} ({raw_event})")


BUILTIN_EVENTS = {}


def register_builtin_event(event_name: str):
    def decorator(cls):
        BUILTIN_EVENTS[event_name] = cls
        return cls
    return decorator


# fullscreen [on|off] WINID
#     The fullscreen state of window WINID was changed to [on|off].
@register_builtin_event("fullscreen")
class EventFullscreen(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=3)

    @property
    def is_fullscreen(self):
        return self.raw_event.args[0] == "on"

    @property
    def win_id(self):
        return self.raw_event.args[1]


# tag_changed TAG MONITOR
#     The tag TAG was selected on MONITOR.
@register_builtin_event("tag_changed")
class EventTagChanged(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=2)

    @property
    def tag_name(self):
        return self.raw_event.args[0]

    @property
    def monitor_idx(self):
        return self.raw_event.args[1]


# focus_changed WINID TITLE
#     The window WINID was focused. Its window title is TITLE.
@register_builtin_event("focus_changed")
class EventFocusChanged(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=2)

    @property
    def win_id(self):
        return self.raw_event.args[0]

    @property
    def win_name(self):
        return self.raw_event.args[1]


# window_title_changed WINID TITLE
#     The title of the focused window was changed. Its window id is WINID and
#     its new title is TITLE.
@register_builtin_event("window_title_changed")
class EventWindowTitleChanged(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=2)

    @property
    def win_id(self):
        return self.raw_event.args[0]

    @property
    def win_name(self):
        return self.raw_event.args[1]


# tag_flags
#     The flags (i.e. urgent or filled state) have been changed.
@register_builtin_event("tag_flags")
class EventTagFlags(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=0)


# tag_added TAG
#     A tag named TAG was added.
@register_builtin_event("tag_added")
class EventTagAdded(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=1)

    @property
    def tag_name(self):
        return self.raw_event.args[0]


# tag_removed TAG
#     The tag named TAG was removed.
@register_builtin_event("tag_removed")
class EventTagRemoved(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=1)

    @property
    def tag_name(self):
        return self.raw_event.args[0]


# tag_renamed OLD NEW
#     The tag name changed from OLD to NEW.
@register_builtin_event("tag_renamed")
class EventTagRenamed(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=1)

    @property
    def old_tag_name(self):
        return self.raw_event.args[0]

    @property
    def new_tag_name(self):
        return self.raw_event.args[1]


# urgent [on|off] WINID
#     The urgent state of client with given WINID has been changed to [on|off].
@register_builtin_event("urgent")
class EventUrgent(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=2)

    @property
    def is_urgent(self):
        return self.raw_event.args[0] == "on"

    @property
    def win_id(self):
        return self.raw_event.args[1]


# rule NAME WINID
#     A window with the id WINID appeared which triggered a rule with the
#     consequence hook=NAME.
@register_builtin_event("rule")
class EventRule(BaseEvent):
    def __init__(self, raw_event: RawEvent):
        super().__init__(raw_event, min_args=2)

    @property
    def is_urgent(self):
        return self.raw_event.args[0] == "on"

    @property
    def win_id(self):
        return self.raw_event.args[1]


def try_parse_builtin_event(raw_event: RawEvent) -> Optional[BaseEvent]:
    if raw_event.name in BUILTIN_EVENTS:
        return BUILTIN_EVENTS[raw_event.name](raw_event)
    else:
        return None
