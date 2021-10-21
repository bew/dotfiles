interception tools:
- add caps2esc with hold timeout at 0.5s

---
FIXME: Wezterm: mouse selection in cell:
-> instead of `[left|middle][middle|right][right|..]`
-> it should do: `[left][middle][right]`
=> DO NOT SPLIT CELLS IN 2

---
TODO?: Nix: repackage ffcast to reference its dependencies (ffmpeg, imagemagick, xprop, xwininfo, ..)
Add helper or add cheatsheet for it, it's _really_ great in KISS and it works perfectly!
NOTE: there's already a Nix package (see https://github.com/lolilolicon/FFcast/issues/21)
=> Idea: rewrite it in Rust?

TODO: Extract ~shell agnostic aliases/functions to /shell in the repo
(like in sg' configs)

--
TODO: share ad-hoc directory aliases with subshells and other tools (editor, ..)
Might be good to not use the raw `hash -d foo=bar` but a helper function where we can hook an addition of foo=bar in an env variable.
| IDEA: use env vars, one for each entry, like `UI_DIR_ALIAS_foo=bar`
| then a function to add/remove-one/remove-all alias(es) is very easy to write!
| => Using an env var preix like `UI_DIR_ALIAS_` means I could use these
|    aliases in more tools than _just_ the shell!
| FIXME: how to handle 1 alias to multiple paths?
|   (enforce same realpath? and patch zsh with realpath checking if needed?)

---
(Try to?) unify keybindings for completion selection & history traversal

-- In shell: (completion & history are exclusive)

history-{next,prev} => A-{j,k}
completion-selection => A-{h,j,k,l} (and others)

-- In fzf (with my own bindings):

history-{next,prev} -- NOT USED / NOT IMPLEMENTED
completion-selection => A-{j,k} (and others)

-- In nvim:

history-{next,prev} => A-{j,k}
completion-selection => C-{n,p}
