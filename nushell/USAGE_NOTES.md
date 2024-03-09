ID: 20231123T0426
tags: #tech #usage-notes

# nushell, usage notes

BAD: There is no way to pause/suspend current process and resume it later (via Ctrl-z then fg)
=> This is BAD as my workflow depends A LOT on this ability!...
(open editor, suspend, try some command, resume editor..)
==> @2024-03 Now I basically only use nushell when I need to manipulate data, not as a main shell..

BAD: The shell does not have the notion of a logical path, it only knows about physical paths and
always resolves symlinks.
Meaning: `cd my-symlink` would resolve the symlink and cd into the target.
ISSUE: https://github.com/nushell/nushell/issues/2175

WEIRD: Syntax priority doesn't give more priority to pipelines..
- `return foo | bar` is parsed as `(return foo) | bar` instead of `return (foo | bar)`
- `if foo | bar { echo baz }` fails parsing but `if foo { echo bar }` works
- `$foo = $bar | merge {baz: 1}` fails saying `merge` can't take nothing.. (`$foo = $bar` outputs nothing)

BUG: In insert mode, `MoveWordRightEnd` & `MoveBigWordRightEnd` are off-by-one.
Issue: https://github.com/nushell/reedline/issues/766

FIXME: Move shell history outside of $XDG_CONFIG_HOME, should be in $XDG_STATE_HOME !
Issue: https://github.com/nushell/nushell/issues/10100

BUG?: Starting in 0.91.0, we can't see the output of commands run by keybindings ☹
Issue: https://github.com/nushell/nushell/issues/12142
