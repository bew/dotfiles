from enum import Enum


class MouseButton(Enum):
    LEFT = "1"
    MIDDLE = "2"
    RIGHT = "3"
    SCROLL_UP = "4"
    SCROLL_DOWN = "5"


def action_start(action: str, button: MouseButton = MouseButton.LEFT) -> str:
    action_escaped = action.replace(":", "\\:")
    return "%{A" + str(button.value) + ":" + action_escaped + ":}"


def action_end() -> str:
    return "%{A}"
