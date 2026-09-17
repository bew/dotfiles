# dynpaths - Dynamic Paths system to avoid Nix rebuilds on demand!

`dynpaths` is a small flake that builds config paths as symlinks whose target can be either
a read-only copy in the Nix store, or a live target anywhere on disk.

It targets Home Manager / NixOS setups where config files are referenced from a flake:
the same configuration yields store copies by default, but can give symlink redirects on-demand.

Here is a sample HM config that declares a `dots` root to my dotfiles repo and uses a dynamic path
for my espanso config folder:
```nix
{
  # (1) global config for a given Nix module system: declare a Root
  dynpaths.roots.dots = {
    nixStorePath = flakeInputs.self;   # store-side base
    realPath = "/home/myuser/.dot";    # live checkout
  };

  # (2) use `mkLink` in your config modules
  xdg.configFile."espanso".source = config.dynpaths.mkLink ./gui-apps/espanso;

  # (3) later / in an override / for a specific home: the single switch
  dynpaths.mode = "dynamic";
}
```
- With `dynpaths.mode = "dynamic"` the link resolves to `/home/myuser/.dot/gui-apps/espanso`.
- With `dynpaths.mode = "static"` (*the default*) the same code produces a link into the store.

## Why

The point is to have a single `dynamic`/`static` switch, **without changing** the config:
Flipping that single switch (global or per root) makes all affected links resolve to their live targets ✨.

=> You do not maintain two configs, rewrite paths, or re-wire imports:
the same `mkLink` call resolves to a store copy or a symlink redirect depending on a single option.

> [!NOTE]
> I (@bew) personally use this for my HM configs that target my dev workstations (personal / work),
> where I want to freely edit my neovim/git/tmux configs without a Nix rebuild step.
>
> For other targets like servers, I don't plan to edit any config and these home profiles can stay
> static.

## Quick start (NixOS / Home Manager)

Add the flake as an input, then import the generic module.
Home Manager users should also import the checker module so the activation-time check runs.

```nix
# flake.nix
inputs.dynpaths.url = "path:./nix/dynpaths-flake"; # FIXME: use repo once extracted!
```

```nix
# home.nix / configuration.nix / ...
{ config, flakeInputs, ... }:
{
  imports = [
    flakeInputs.dynpaths.modules.generic.dynpaths
    # Home Manager only — wires `checkerScript` into `home.activation`.
    flakeInputs.dynpaths.modules.homeManager.dynpathsChecker
  ];

  # The single switch. Leave this as "static" for store copies.
  dynpaths.mode = "dynamic";
  dynpaths.roots.dots = {
    nixStorePath = flakeInputs.self;      # store-side base
    realPath = "/home/myuser/.dot";    # live checkout
  };

  # Create a link and register it for activation-time checking.
  xdg.configFile."espanso".source = config.dynpaths.mkLink ./gui-apps/espanso;
  dynpaths.checkedPaths = [ config.xdg.configFile."espanso".source ];
}
```

> [!NOTE]
> `realPath` must be an absolute path string outside the store.
> A relative path literal (`./dot`) is coerced by Nix into a store path and silently breaks the
> contract.

## How it works

Example dynamic rewrite of a path literal before it reaches the store:
```text
For a root 'dots' defined as:
   /nix/store/thehash-src  ->  /home/myuser/.dot
       nixStorePath                realPath

mkLink ./gui-apps/espanso
-> Nix value: /nix/store/thehash-src/gui-apps/espanso
   (would-be store path; nothing copied yet)

-> Resolver matches a Root by its nixStorePath prefix:
      /nix/store/thehash-src/gui-apps/espanso
      └─── 'dots' root! ───┘

-> Nix only sees a symlink redirect to /home/myuser/.dot/gui-apps/espanso
                                       └── replaced! ──┘
```

Links are created via `config.dynpaths.mkLink givenPath`, whose resolver matches the path's
_would-be_ Nix store path against the declared *Roots* and applies the *Effective mode*:

| Condition | Result | Copied to the store |
| --- | --- | --- |
| No *Root* matches | the path unchanged | the content |
| Matched *Root*, `static` | the path unchanged | the content |
| Matched *Root*, `dynamic` | a *symlink redirect* | only the symlink, not the content |

**Important terms**:

| Term | Meaning |
| --- | --- |
| Root | A named `{ nixStorePath, realPath, mode? }` pairing a store-side base with a live base |
| Effective mode | `matchedRoot.mode` when set, otherwise the global `dynpaths.mode` |
| Symlink redirect | Symlink derivation pointing at the real target |
| Store copy | The given path unchanged; Nix copies its content into the store on use |
| Resolver | Generic code that selects a *Root* for a path and builds the link if needed |

> [!TIP]
> **Why `mkLink` is needed**:
>
> When using `./foo/bar` directly in a Nix config, uses of that path in build will always copy that
> path target in the Nix store at e.g. `/nix/store/...-source/something/foo/bar` and reference it
> where it's needed.
>
> Using `mkLink` function will instead convert the `./foo/bar` path to its _would-be_ nix store path
> (WITHOUT copy to the store, using `toString ./the/path`), then try to match a registered root for
> rewrite as an 'out-of-store' symlink, similar to HM's `config.lib.file.mkOutOfStoreSymlink`.

## Matching rules

Resolution happens in two phases: pick a *Root*, then apply its *Effective mode*.

1. A *Root* matches when its `nixStorePath` is a *path-component* prefix of the given path:
   either equal to it, or followed by `/…`.
   This ensures that a root at `/nix/store/aaa-src` is _not used_ for `/nix/store/aaa-srcXYZ/foo`.
2. The longest matching `nixStorePath` wins, so a nested *Root* always beats its parents.

> [!WARNING]
> Two *Roots* with the same `nixStorePath` make resolution ambiguous and fail evaluation.

Example with two valid roots:
- `dots`: `nixStorePath = "/nix/store/aaa-src"`, `realPath = "/home/myuser/.dot"`
- `nvim-dev`: `nixStorePath = "/nix/store/aaa-src/nvim"`, `realPath = "/home/myuser/projects/nvim-dev"`

| Given path | Matched root | Result |
| --- | --- | --- |
| `/nix/store/aaa-src/gui-apps/espanso` | `dots` | `/home/myuser/.dot/gui-apps/espanso` |
| `/nix/store/aaa-src/nvim/lua/init.lua` | `nvim-dev` | `/home/myuser/projects/nvim-dev/lua/init.lua` |
| `/nix/store/aaa-srcXYZ/foo` | none | store copy (unchanged) |
| `/nix/store/bbb-other/foo` | none | store copy (unchanged) |

## Activation checking

`dynpaths.checkerScript` is non-null exactly when at least one Root resolves to dynamic.
It is a shell script that checks, for each entry in `dynpaths.checkedPaths`, that the link's
real target exists on the filesystem.
Entries without a `dynpathRedirectTarget` passthru (store copies) are silently skipped.

A missing target prints a line per missing target and exits non-zero:
```
dynpaths: symlink redirect target does not exist: '/home/myuser/.dot/foo' (matched root: dots)
```
With `modules.homeManager.dynpathsChecker` imported, the script runs as an activation step before
`writeBoundary`, so activation aborts before any filesystem changes if any target is missing.

> [!TIP]
> Register the final option value in `dynpaths.checkedPaths` rather than the `mkLink` result directly,
> so any later override of that option is also checked:
>
> ```nix
> xdg.configFile."espanso".source = config.dynpaths.mkLink ./gui-apps/espanso;
> dynpaths.checkedPaths = [ config.xdg.configFile."espanso".source ];
> ```

> [!NOTE]
> Symlink redirect derivations expose two passthru attributes for inspection and tooling:
> - `dynpathRedirectTarget`: the real path the link resolves to.
> - `dynpathMatchedRoot`: `{ name, nixStorePath, realPath }` of the matched Root.

## Options reference

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `dynpaths.mode` | `dynamic`/`static` | `static` | Mode for *Roots* without `mode`. |
| `dynpaths.roots` | attrset of *Root* | `{ }` | Named *Roots* (see below). |
| `dynpaths.mkLink` | `path -> package` | managed by module | Link factory: store copy or symlink redirect. |
| `dynpaths.checkedPaths` | list of package | `[ ]` | Links to verify at activation. |
| `dynpaths.checkerScript` | `package` or null | read-only | Null unless a *Root* is dynamic. |

Each *Root* has the following shape:

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `nixStorePath` | `pathInStore` | required | Store-side base; may be a nested subdir. |
| `realPath` | `path` | required | Absolute live base, outside the store. |
| `mode` | `null` / `"dynamic"` / `"static"` | `null` | Per-*Root* override; else global. |

> [!NOTE]
> `dynpaths.mkLink` is assigned by the `dynpaths` module and is meant to be *called*
> (via `config.dynpaths.mkLink`), not configured.

## Toolkit module

FIXME: this is specific to my dotfiles repo!

`modules.kitsys.dynpaths` is one of the base module for the toolkit system in this repo.
It adds `dynpaths.roots` + `dynamicConfig.{isSupported,enable,tryEnable,isEffectivelyEnabled}` and
assigns `lib.mkLink` from the same resolver, so resolution behaves identically.
Here `dynamicConfig.isEffectivelyEnabled` provides the global mode — `true` acts like `"dynamic"`,
`false` like `"static"` — and a per-Root `mode` still wins.
The entries in `dynpaths.roots` have the same *Root* shape as in the generic module.
See `../DESIGN_config_system.md` for the kit/module/preset concepts.

## Development

Run the unit checks:
```sh
nix flake check
```
The checks live in `./checks.nix` and cover *Root* resolution (nested *Roots*, path-component
boundaries, per-*Root* mode overrides, duplicate-`nixStorePath` errors) and the checker script.
