# PLAN — using-look-on-macos

Custom `Look` (https://github.com/kunkka19xx/look) sources for this macOS workstation.
Drop these into `~/.look/sources/`, reload with `Cmd+Shift+;`.

---

## 1. Nix store stats

List installed packages with their store path sizes.
Drills down to GC on `Cmd+K`.

```toml
[nix-store-stats]
name    = "Nix store"
preview = "nix path-info -S {id}"
then    = ["nix-gc"]

[nix-store-size]
name  = "Store size"
icon  = "💾"
do    = ["nix path-info -sSh /run/current-system/sw"]
```

**FIXME:** json-format `run` block listing all store paths may be too slow/unbounded.
Alternative: `do` block showing aggregate stats (`nix-store --query --referrers`,
`du -sh /nix/store`) via a single command, no row listing.

---

## 2. Nix GC

Guard with `confirm` since this is destructive.
Could live as a standalone `do` block or as a `then` target reachable from stats.

```toml
[nix-gc]
name    = "Nix garbage collect"
icon    = "🗑️"
confirm = "Run nix store gc?"
do      = [
  "nix store gc",
]
```

**Open question:** `nix store gc` vs `nix-collect-garbage -d`?
The former is the new CLI, the latter handles old profiles.
Figure out which is correct for this machine.

---

## 3. Project dirs (`~/work/*/*`)

Two-level project tree (`client/project`).
`depth = 2` brings in intermediate org/client dirs — maybe filter to `only = "dirs"` + `match` on known patterns, or accept the flat list and use `depth = 1` on a flatter layout.

```toml
[work-projects]
name    = "Work"
dir     = "~/work"
depth   = 2
only    = "dirs"
aliases = ["project", "repo"]
```

**FIXME:** depth=2 includes `~/work/client-a/` dirs as rows alongside `~/work/client-a/proj-b`.
Options:
- `depth = 1` + flatten subdirs via a `run` script that lists `~/work/*/*` only.
- Keep `depth = 2` and set `bias` low — the intermediate dirs are clutter but harmless.
- Script it: `run = "find ~/work -mindepth 2 -maxdepth 2 -type d"`.

---

## Open questions

- Nix store listing: aggregate summary only, or per-path rows?
- `nix store gc` vs `nix-collect-garbage -d`?
- Project layout: `~/work/*` (flat) or `~/work/*/*` (nested)?
- Where should the `.toml` live in the dotfiles repo, and symlink from `~/.look/sources/` or point `LOOK_SOURCES_DIR`?
