# Item File Format

Each Item: Markdown file with YAML frontmatter + free-text body.

## Anatomy

```markdown
---
when: next
kind: fix
scopes: @dotfiles @nvim
added: 2026-06-13T14:23:01
source: cli
---

Fix the broken symlink for nvim spell directory.
Maybe also check if the parent dir is created in the nix module.
```

## Frontmatter schema

### Required fields

| Field | Type | Description |
|---|---|---|
| `when` | `next \| soon \| someday \| maybe` | Urgency level |
| `kind` | string | Action type — predefined canonical value or free-form |
| `added` | ISO 8601 datetime | Creation timestamp (local time) |
| `source` | `cli \| opencode` | Where the item was created |

### Optional fields

| Field | Type | Description |
|---|---|---|
| `scopes` | space-separated `@word` list | Scope tags; auto-detected + inline @-tokens |

`scopes` omitted when no scope detected and none provided inline.

### Predefined `kind` values

| Canonical | Aliases | Meaning |
|---|---|---|
| `todo` | `t`, `td` | Generic task to do |
| `fix` | `fx`, `f` | Bug or breakage to fix |
| `try` | `tr` | Something to experiment with |
| `spec` | `sp` | Thing to design or write a spec for |
| `idea` | `i` | Loose thought or concept |

Any free-form string valid as `kind`.
Alias table applies to CLI subcommands only (see [cli.md](cli.md)); frontmatter always stores full string as given.

## Body

Free-form Markdown after closing `---`.
No structure enforced; for human reading/editing only.
May be empty for quick captures.
