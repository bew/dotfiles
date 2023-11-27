ID: 20231123T0426
tags: #tech #usage-notes

# nushell, usage notes

BAD: There is no way to pause/suspend current process and resume it later (via Ctrl-z then fg)
=> This is BAD as my workflow depends A LOT on this ability!...
(open editor, suspend, try some command, resume editor..)

BAD: The shell does not have the notion of a logical path, it only knows about physical paths and
always resolves symlinks.
Meaning: `cd my-symlink` would resolve the symlink and cd into the target.
ISSUE: https://github.com/nushell/nushell/issues/2175

BAD: Globs are inconsistent and hard to use, and are sometimes done by each command not by the shell..
https://github.com/nushell/nushell/issues/9558
https://github.com/nushell/nushell/issues/9310 (about paths with `[` & `]` in them)


WEIRD: Syntax priority doesn't give more priority to pipelines..
- `return foo | bar` is parsed as `(return foo) | bar` instead of `return (foo | bar)`
- `if foo | bar { echo baz }` fails parsing but `if foo { echo bar }` works
- `$foo = $bar | merge {baz: 1}` fails saying `merge` can't take nothing.. (`$foo = $bar` outputs nothing)

WEIRD: With vi keybindings mode, Escape in insert mode goes to normal mode, BUT doesn't move the
cursor 1 char to the left.. Very dis-orienting!!


BUG: Terminal scrollback is very dirty when using the hint system or completion menus...
(tested under tmux for the menus on Linux, and in plain wezterm on Windows)

BUG: In insert mode, `MoveWordRightEnd` & `MoveBigWordRightEnd` are off-by-one.


FIXME: Move shell history outside of $XDG_CONFIG_HOME, should be in $XDG_STATE_HOME ?
