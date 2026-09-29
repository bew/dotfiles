---
name: coder-zsh
description: |
  Zsh code writing guidelines: idioms, completions, and shell gotchas.
  Always load when asked to draft/write/edit/refactor/review zsh code files.
metadata:
  maintainers: [bew]
---

## Goal

Write zsh code with native idioms, correct option parsing, working completion functions, and safe
exit-status handling, building on `coder-generic` conventions.

REQUIRES: load `coder-generic` skill first.

## Rules

- Use `[[ ... ]]` over `[ ... ]` for conditional expressions.
- Use `(( ... ))` over `[[ ... ]]` for numeric comparisons.
- Always quote expansions: `"$var"`, `"$@"`, `"${arr[@]}"`.
- Use `function name() { ... }` style — always include the `function` keyword.
- Use `${VAR:-default}` for optional values and defaults.
- Assign positional parameters to named locals at the top of a function;
  use `$1` directly only in trivial one-liners.

## Completions

- Name completion functions with a leading `_` and register them with `compdef`.
- Register against the real command name: `compdef _foo foo`.
  Aliases are expanded before completion runs, so the alias name is not required.
- Keep completers small; prefer built-in helpers (`_arguments`, `_files`, `_directories`) over
  hand-rolled matching.
- If a completer deliberately does not handle some flag/args, note it in a comment.

```zsh
function _foo() {
  _arguments '1:subdir:_directories'
}
compdef _foo foo
```

## Output capture vs exit-status

Declare a local on its own line before capturing command output:
`local` masks the substitution's exit status, so a guard on the same line never fires.

```zsh
# Good — the guard sees the real exit status
local root
root=$(resolve_root) || return 1

# Bad — `local` reports 0, the guard is dead, and `root` may be empty
local root=$(resolve_root) || return 1
```
