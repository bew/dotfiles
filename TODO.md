interception tools:
- add caps2esc with hold timeout at 0.5s

---
Wezterm:
mouse selection in cell:
-> instead of `[left|middle][middle|right][right|..]`
-> do: `[left][middle][right]`
=> DO NOT SPLIT CELLS IN 2

---
Nix: repackage ffcast to reference its dependencies (ffmpeg, imagemagick, xprop, xwininfo, ..)
Add helper or add cheatsheet for it, it's _really_ great in KISS and it works perfectly!
Idea: rewrite it in Rust?

---
(Try to?) unify keybindings for completion selection & history traversal

-- In shell: (completion & history are exclusive)

history-{next,prev} => A-{j,k}
completion-selection => A-{h,j,k,l} (and others)

Extract ~shell agnostic aliases/functions to /shell in the repo
(like in sg' configs)

-- In fzf (with my own bindings):

history-{next,prev} -- NOT USED / NOT IMPLEMENTED
completion-selection => A-{j,k} (and others)

-- In nvim:

history-{next,prev} => A-{j,k}
completion-selection => C-{n,p}
