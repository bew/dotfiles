# This file needs to be installed in `~/.ipython/profile_default/startup/`
#
# Ref: https://ipython.readthedocs.io/en/stable/interactive/tutorial.html#configuration
# Ref: https://ipython.readthedocs.io/en/stable/config/details.html#keyboard-shortcuts

from collections.abc import Callable
from typing import Any, cast

from IPython import get_ipython
from IPython.terminal.interactiveshell import TerminalInteractiveShell
from prompt_toolkit.enums import DEFAULT_BUFFER
from prompt_toolkit.keys import Keys
from prompt_toolkit.buffer import Buffer
from prompt_toolkit.key_binding.bindings import named_commands as nc
from prompt_toolkit.key_binding.key_processor import KeyPress, KeyPressEvent
from prompt_toolkit.filters import HasFocus, ViInsertMode, EmacsInsertMode
from prompt_toolkit.shortcuts import PromptSession


def test_key_action(event: KeyPressEvent):
    event.current_buffer.insert_text("TEST!")


def buf_action(fn: Callable[[Buffer], Any]):
    def inner(event: KeyPressEvent):
        fn(event.current_buffer)
    return inner


def dismiss_completion_if_any(event: KeyPressEvent):
    buf: Buffer = event.current_buffer
    if buf.complete_state:
        buf.cancel_completion()


def left_completion_or_left(event: KeyPressEvent):
    buf: Buffer = event.current_buffer
    if buf.complete_state:
        # I didn't find dedicated function to move selection to the left/right in the completion
        # menu, so this is basically a key remap, feeding a KeyPress in the input stack.
        event.app.key_processor.feed(KeyPress(Keys.Left))
    else:
        nc.backward_char(event)


def right_completion_or_right(event: KeyPressEvent):
    buf: Buffer = event.current_buffer
    if buf.complete_state:
        # I didn't find dedicated function to move selection to the left/right in the completion
        # menu, so this is basically a key remap, feeding a KeyPress in the input stack.
        event.app.key_processor.feed(KeyPress(Keys.Right))
    else:
        nc.forward_char(event)


def alt(*keys) -> tuple:
    # Ref: https://python-prompt-toolkit.readthedocs.io/en/master/pages/advanced_topics/key_bindings.html#binding-alt-something-option-something-or-meta-something
    return ("escape", *keys)


def setup_my_keys(key_registry):
    my_insert_keys = {
        # Core movement
        # h/l: left/right in-completion/in-buffer
        # j/k: down/up in-completion/in-buffer/in-history
        alt("h"): left_completion_or_left,
        alt("j"): buf_action(lambda b: b.auto_down()),
        alt("k"): buf_action(lambda b: b.auto_up()),
        alt("l"): right_completion_or_right,

        # Horizontal movement
        alt("b"): nc.backward_word,
        alt("w"): nc.forward_word,
        alt("^"): nc.beginning_of_line,
        alt("$"): nc.end_of_line,

        # History
        alt("K"): buf_action(lambda b: b.history_backward()),
        alt("J"): buf_action(lambda b: b.history_forward()),

        # Undo/Redo
        alt("u"): buf_action(lambda b: b.undo()),
        alt("U"): buf_action(lambda b: b.redo()),  # FIXME: redo is broken!
        # About redo being broken, I opened an issue on prompt_toolkit repo:
        # https://github.com/prompt-toolkit/python-prompt-toolkit/issues/1703

        # Line above/below
        alt("O"): buf_action(lambda b: b.insert_line_above(copy_margin=True)),
        alt("o"): buf_action(lambda b: b.insert_line_below(copy_margin=True)),

        # Other...
        alt("q"): dismiss_completion_if_any,
        alt("c-e"): nc.edit_and_execute, # Ctrl-Alt-e
    }
    insert_cond = HasFocus(DEFAULT_BUFFER) & (ViInsertMode() | EmacsInsertMode())
    for keys, action in my_insert_keys.items():
        key_registry.add_binding(*keys, filter=(insert_cond))(action)


def setup_config(shell: TerminalInteractiveShell):
    # Automatically add/delete open/close brackets or quote (<3)
    shell.auto_match = True
    # No confirm prompt when exiting (with e.g.: Ctrl-d)
    shell.confirm_exit = False
    # like Vim's (but as a float)
    shell.timeoutlen = 0.1
    # Require magic commands to be prefixed with %.
    shell.automagic = False

    try:
        # Rich has an ipython extension for nicer UI elements :)
        # See: https://rich.readthedocs.io/en/stable/introduction.html#ipython-extension
        import rich
        shell.extension_manager.load_extension("rich")
        print("note: 'rich' extension loaded \\o/")
    except ImportError:
        print("note: Unable to `import rich`, 'rich' extension not loaded")

    prompt_toolkit_app = cast(PromptSession, shell.pt_app)
    setup_my_keys(prompt_toolkit_app.key_bindings)


# Setup my config is IPython is a terminal interactive shell!
_ip = get_ipython()
if isinstance(_ip, TerminalInteractiveShell):
    setup_config(_ip)
