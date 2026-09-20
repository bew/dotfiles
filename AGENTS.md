# dotfiles repo — agent instructions

## Paths equivalence

`~/.dot` is well known symlink to this repo (dotfiles root).
Any paths like `<repo>/foo` & `~/.dot/foo` are equivalent.

### opencode alias

`~/.config/opencode` is symlink to `~/.dot/opencode` (this repo's `opencode/`).

Example: These paths are equivalent, they all resolve to the exact same file on disk (same inode):
- `~/.config/opencode/skills/foo/SKILL.md`
- `~/.dot/opencode/skills/foo/SKILL.md`
- `<repo>/opencode/skills/foo/SKILL.md`

## Nix formatting

Never run `nixfmt` (or any formatter) on Nix files in this repo.
Match the existing hand formatting instead.
