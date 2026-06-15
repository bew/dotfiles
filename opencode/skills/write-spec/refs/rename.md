# Renaming a Spec

Used when: spec name/slug changes (temporary name replaced, concept renamed, etc.)
Also used during promotion (`_WIP_SPECS/` → `_SPECS/`).

## Steps

Run `<skill-dir>/scripts/rename-spec`:

```sh
<skill-dir>/scripts/rename-spec <from-path> <to-path>
```

Flags: `--skip-git-check`

Follow any instructions printed by the script.

## After rename

1. Update `$slug`, `$specdir`, `$specpath` in session.
2. If name changed (not just promotion): update H1 of `$specpath` to reflect new name.
