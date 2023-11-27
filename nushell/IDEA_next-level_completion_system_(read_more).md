# IDEA for nushell: Next-level completion system

## Fallback completions / scripted completers

For typo corrections, any-case match, ..


## Completion groups

I want more completion flexibility, inspired from `zsh`'s completion system but with a
lot more structure thanks to nushell's structural data flow and manipulations.

Example of groups:
- for many commands: options, dirs, files
- for `git checkout`: modified files, local heads, remote heads, recent commit
- for `cd`: local dirs, recent dirs (session), recent dirs (any shells)
- for `cd ~`: named dirs, users
- for `man`: 1 group per man sections

I want to be able to:
1. Expose multiple completions groups
2. Have keybinds to navigate in a completion menu through the completion groups
3. Re-order the groups for some completions

IDEA: completion tags not groups
Completion items can have 1+ tags (?)
In results we can filter which results we want with `#options`, `#path` or `!#git.untracked`...

### Notes

https://github.com/nushell/nu_scripts/blob/main/custom-completions/git/git-completions.nu has many
ideas, but AFAIK (NEED CONFIRMATION) it will put all results in the same list, and we can't see only
some completions

FIXME: `export extern "git branch" [...]` do not distinguish options & pos-param..


## Results filtering: Fuzzy search / Search anywhere

TODO!


## Results display: item format

To show some additional data about the item, e.g. as a prefix.
For example `eza`(-like) output with file size, number of changes hunk, ...

We could also show an icon before all local paths
`compl_item_format: "<icon> <item><flex-align-spacing><description>"`
