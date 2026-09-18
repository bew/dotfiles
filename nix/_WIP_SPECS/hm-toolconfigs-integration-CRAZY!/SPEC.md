# [MAYBE-READY] `toolcfg` in Home Manager (and its `dynpaths.roots` wiring)

> IMPORTANT: Before any drafting/planning/editing of this spec,
> agents MUST load one of the spec-writing skill first.

## Introduction

Tool configs in this repo are built by toolkits and evaluated at flake-evaluation time, before Home Manager ever runs.
Each evaluation produces `outputs.homeModules.{withDefaults,specific}`, which homes import to install the tool and its config.
Because that evaluation happens outside Home Manager, anything it resolves — most notably `dynpaths` link targets — is fixed for every home that imports it.

This spec introduces `toolcfg`, a Home Manager-side namespace that makes HM tool outputs aware of per-home configuration.
The primary goal is wiring `toolcfg` into my HM configs so the installed tool outputs can read it.
A secondary goal is wiring `dynpaths.roots` so each home resolves its tool-config symlink redirects against its own live paths.
The secondary goal is a slim justification on its own; the hypothesis is that once the primary goal exists, it may work by default and need little or no extra mechanism.

The driving use-case is my dev workstations: I want to edit nvim, tmux, and zsh configs in a live checkout and have Home Manager install links that resolve to that checkout, while servers and other targets keep static store copies.
Today that split requires roots to be injected per home at flake-eval time (`mkKitConfigsDynamic` in `flake.nix`); instead, a home should declare what it wants and the tool outputs should honor it.

A second driving use-case is reducing the custom patching done in `flake.nix`.
The home's dynamic roots should propagate to the `dynpaths.roots` of the tool configs that the home imports, so the per-home root injection and its associated wrapping code can be removed rather than extended.

Inspirations:
- `nix-dynpaths` (repo `../nix-dynpaths`): the *Root*, *Effective mode*, resolver, and `mkLink` that already give one config both static and dynamic behavior.
- The kit-system `lib.extendWith` and `defineEval` machinery that re-evaluates a tool config with extra modules.
- The `extraSpecialArgs` vs `imports` constraint documented at `flake.nix:10-22`, which rules out choosing imported modules from config values.

## Interface / How to use

### Home-side declaration

Homes keep importing the tool outputs they already import, and gain a `toolcfg.<name>` namespace for per-tool customization.

The mixed-case names (`toolConfigs` flake output, `kitConfigs` HM argument) disappear.
The flake output stays lowercase `toolconfigs` and is passed to HM as `toolconfigsForImports`; the HM config namespace is `toolcfg`, so the two never collide.

```nix
{ config, toolconfigsForImports, ... }:
{
  imports = [
    toolconfigsForImports.nvim-bew.outputs.homeModules.specific
    toolconfigsForImports.tmux-bew.outputs.homeModules.withDefaults
    toolconfigsForImports.zsh-bew.outputs.homeModules.withDefaults
  ];

  # Existing generic dynpaths module: the home's global live checkout.
  # (path literal; relative to this module file)
  dynpaths.mode = "dynamic";
  dynpaths.roots.dots = {
    nixStorePath = ./.;
    realPath = "/home/bew/.dot";
  };

  # Per-tool overrides.
  toolcfg.tmux-bew.dynpaths.mode = "static";   # this one stays a store copy
  toolcfg.nvim-bew.dynpaths.roots.plugins = {  # extra named Root, tool-scoped
    nixStorePath = ./nvim-myplugins;
    realPath = "/home/bew/projects/nvim-myplugins";
  };
}
```

`toolcfg.<name>` mirrors the toolconfig's option tree — a subset of it — so `dynpaths` is one branch and more branches can be exposed later.
A toolconfig's recomputed outputs are exposed read-only as `toolcfg.<name>.outs`.

### Install outputs

The install outputs `outputs.homeModules.{withDefaults,specific}` become module functions instead of plain modules.
A plain attrset is built at toolkit-eval time and cannot see the home's `config`; the function form is what lets them read `config.toolcfg.<name>.outs` at HM evaluation time.
Importing is identical either way.

```nix
# toolkit base, conceptually
outputs.homeModules.specific = { config, lib, pkgs, ... }: {
  xdg.configFile.${appname}.source = config.toolcfg.${name}.outs.nvimDir;
  home.packages = [ config.toolcfg.${name}.outs.toolPkg.standalone ];
  config.dynpaths.checkedPaths = [ ... ];
};
```

NOTE: install outputs must stay usable without the integration imported; they must not hard-fail on a missing `config.toolcfg`.

NOTE: `toolcfg.<name>` cannot select which module is imported — imports resolve before config values (`flake.nix:10-22`).
A disabled or overridden toolconfig can only change behavior inside an already-imported module, not remove it from `imports`.

### Open Questions

1. What is the canonical `<name>` key?
   Non-blocking. Flake keys (`nvim-bew`, `tmux-bew`) are stable and user-facing; eval `ID`s (`bew` for tmux) are what modules already carry.
2. How is the toolkit HM integration separated from the install outputs?
   Non-blocking. Needs a clean split so configuring a toolconfig does not install it, while install outputs still work unchanged.
3. Could the `specific` / `withDefaults` import modules be removed entirely?
   Non-blocking. Raises further questions about how tools get installed and configured; revisit later.
4. Is an `enable`/`disable` toggle needed, or are per-tool option overrides sufficient?
   Non-blocking. A toggle cannot remove an import, so it can only make a module a no-op.
5. How much of a toolconfig's option tree is exposed to HM, and how is that subset declared?
   Non-blocking. Relates to the namespace list in Part 1.

## Part 1 — Toolkit HM integration

The integration is the configure-only layer: it exposes `toolcfg`, recomputes a toolconfig's outputs against the home config, and installs nothing.
It is shipped by each toolkit and imported generically from `flake.nix`, so every home gets it without per-tool imports.

### Declared namespaces

The toolkit — on its kit or on each tool-config definition — declares a list of option-namespaces to expose to HM.
For now the list contains only `dynpaths`; generalising it is an open question.
Each declared namespace declares `options.toolcfg.<name>.<ns>`, reusing the toolconfig's submodule types so the HM surface stays in sync with the toolconfig.

IDEA: the integration could walk that namespace list to dynamically define the options available on the HM module.

Walkthrough (conceptual, `tmux` as the example):

```nix
# 1. The tool-config definition declares which namespaces HM may configure.
#    tmux/bew-config.tmuxkit-module.nix (conceptually)
{
  hm.exportNamespaces = [ "dynpaths" ];
}
```

```nix
# 2. The integration reads that list and defines the matching HM options,
#    reusing the toolconfig's own submodule type for that namespace.
#    toolkit integration (conceptually)
{ lib, toolconfig, ... }:
{
  options.toolcfg.${name}.dynpaths = lib.mkOption {
    type = toolconfig.namespaces.dynpaths.type;
    default = { };
  };
}
```

### Recomputation via extendWith

The integration owns the `extendWith`.
It builds an override import from exactly the declared namespaces — symmetric with what it exposes — and re-evaluates the flake toolconfig with it: `toolconfigsForImports.<name>.lib.extendWith { imports = [ override ]; }`.
The recomputed outputs are lazy and are exposed read-only as `toolcfg.<name>.outs`.

Walkthrough (continuing the same example):

```nix
# 3. The home sets values, or leaves them to the hybrid defaults.
toolcfg.tmux-bew.dynpaths.mode = "static";
```

```nix
# 4. The integration turns exactly the declared namespaces into an override
#    import and re-evaluates the flake toolconfig with it.
{ config, toolconfigsForImports, ... }:
let
  override = {
    dynpaths = {
      roots = config.toolcfg.tmux-bew.dynpaths.roots;
      mode = config.toolcfg.tmux-bew.dynpaths.mode;
    };
  };
  recomputed = toolconfigsForImports.tmux-bew.lib.extendWith {
    imports = [ override ];
  };
in
{
  # 5. Expose the recomputed outputs read-only under the HM namespace.
  #    Lazy: `outs.*` is only forced when an install output reads it.
  config.toolcfg.tmux-bew.outs = recomputed.outputs;
}
```

### Hybrid defaults

A namespace's values default to the home's global `dynpaths`: `toolcfg.<name>.dynpaths.roots` defaults to `config.dynpaths.roots`, and `mode` to `config.dynpaths.mode`.
Setting a per-tool value overrides only that tool; unset tools follow the home.
The mapping is not literal: a dynamic home `mode` is applied as the toolconfig's `dynamicConfig.tryEnable`, since a toolconfig gates dynamic-ness on `dynamicConfig.isSupported` and does not expose `dynpaths.mode`.
This is what makes the `dynpaths.roots` wiring largely automatic.

### Eval-time flow

1. `flake.nix` builds the toolkit integration modules and imports them generically.
   Needed because `config.toolcfg` must exist before any home sets it, and generic import spares each home from importing per tool.
2. It passes the flake `toolconfigs` bundle to HM as `extraSpecialArgs.toolconfigsForImports`.
   Needed because install modules are referenced in `imports`, which resolves before config values (`flake.nix:10-22`); the bundle is the base that gets extended.
3. During HM evaluation the home sets `toolcfg.<name>.*`.
   Needed to give each tool the home's live paths without the toolkit re-reading the home config at flake-eval time.
4. The integration merges those values back into the toolconfig via `extendWith` and exposes the lazy recomputed `outs`.
   Needed because the recomputation can only happen once home config values exist.

### Error handling with asserts

NOTE: this mechanism stacks several evaluation layers (flake toolconfig, toolkit base, integration, HM config, recomputed `outs`).
An error raised deep in that stack is otherwise hard to attribute, so asserts and explicit failures are required at every layer boundary, wherever they can be placed.

Suggested failure points, mirroring existing precedents (`dynpaths` duplicate-`nixStorePath` throw, kit-system `checkAssertsAndWarnings`, the warning when dynamic mode has no roots):
- A home sets `toolcfg.<name>.*` for a `<name>` the integration does not know.
- A toolkit declares a namespace the integration cannot expose, or vice versa.
- The override import or `outs` accesses `config.toolcfg` before the integration is imported.
- A toolconfig with `dynamicConfig.isSupported = false` is asked for dynamic mode.
- Resolved links carry no matching root, or two roots share an `nixStorePath`.
- An install output is imported without the integration and must fail with a pointed message, not a bare attribute error.

Prefer `assert`/`throw` messages that name the layer and the offending `<name>`/namespace.

### Open Questions

1. What exactly does the toolkit hand the integration so it can define the HM options?
   Non-blocking for `dynpaths`; it needs the roots submodule plus the mode→`dynamicConfig.tryEnable` mapping. Generalising beyond `dynpaths` is what makes this non-trivial.
2. How is the override import built so it merges back exactly the declared namespaces?
   Non-blocking. Relates to the namespace-list shape.
3. Does the namespace list live on the `<tool>kit` or on each tool-config definition?
   Non-blocking. The tool-config definition is more specific; the kit is more reusable.
4. Is there recursion risk when `outs` is consumed while building the override?
   Non-blocking. The namespace options feeding the override must not reference `outs`.
5. Where do the boundary asserts live (kit, integration, dynpaths, install outputs)?
   Non-blocking. Spreading them risks duplication; centralising them in the integration may miss toolconfig-internal failures.

## Part 2 — `dynpaths.roots` wiring

Part 1 makes most of this wiring automatic: `toolcfg.<name>.dynpaths.roots` defaults to the home's `config.dynpaths.roots`, and the home's `dynpaths.mode` maps to the toolconfig's `dynamicConfig.tryEnable` (see Hybrid defaults).

Mode mapping detail: a toolconfig does not expose `dynpaths.mode`; dynamic-ness is controlled by `dynamicConfig.{isSupported,tryEnable,enable}` and resolved by `isEffectivelyEnabled` (`../nix-dynpaths/dynpaths.toolkit-module.nix:53-64`).
A home's `dynpaths.mode = "dynamic"` therefore becomes `dynamicConfig.tryEnable = true` on each toolconfig.
A toolconfig that declares no dynamic support (e.g. zsh) then stays static instead of erroring, by the existing `tryEnable`/`isSupported` semantics.

The remaining work in this part:
- Confirm the per-home `dynpaths.roots.dots` propagates to each toolconfig's recomputed `outs` without further plumbing.
- Feed the recomputed resolved links into `config.dynpaths.checkedPaths` so the HM checker validates them at activation, as `gui.nix` does today.
- Define per-tool extra roots (`toolcfg.<name>.dynpaths.roots.<root>`, e.g. `nvim-bew`'s `nvim-myplugins`) that do not exist globally.

NOTE: per-tool roots are confined to that toolconfig's override; they do not propagate upward, so there is no cross-tool or global leakage.

NOTE: it is possible this part needs little or no new mechanism and mostly falls out of Part 1; that is to be confirmed during implementation.

### Open Questions

1. Does the global `dynpaths.roots` reach tool configs purely through the hybrid defaults, or is extra plumbing required?
   Non-blocking. Depends on how Part 1's override import is built.
2. How do recomputed `outs` register in `config.dynpaths.checkedPaths`?
   Non-blocking. Install outputs already register static links there; dynamic roots may need the checker path instead.

## Tool-outputs inventory

### Open Questions

1. Deferred: enumerate per-toolkit the consumed `outputs.*` and which are redirectable vs derived/static.
   Non-blocking. Not needed for the dynpaths-propagation POC; revisit when the `outs` rewrite is implemented.

## Placement / Scope

- The integration is a toolkit-module (under `nix/kits/`), intended to become mostly generic and to be added to `newToolkit`'s `baseModules` so every toolkit gets it.
- First step: add and import it only for the simplest toolkit, `tmuxkit`, before generalising.
- The `toolcfg` namespace reuses dynpaths types from external `nix-dynpaths`; the resolver is not reimplemented.
- Scope is Home-Manager only: standalone `packages.*` and `nix run` keep static store copies.
- Roots are per-home; there is no cross-home coupling, and multi-host is just each home declaring its own `dynpaths.roots`.
- Changes land in dotfiles; no nixpkgs involvement.

### Open Questions

1. When does the integration graduate from tmuxkit-only to `newToolkit`'s `baseModules` for all toolkits?
   Non-blocking. Depends on proving it on tmux first.
2. Does generalising it require a new module in `nix-dynpaths`, or do the existing types and resolver suffice?
   Non-blocking. Relates to how HM-specific the integration module is.

## Alternatives & Tradeoffs

- **T1 — reuse the home's generic `config.dynpaths.mkLink` in install outputs**, with no `toolcfg` namespace.
  Simplest, but all tools share one root set and there is no per-tool control.
- **T2 — re-evaluate the whole toolkit inside HM.**
  Removes the flake-time bundle, but fights the `imports`-before-config constraint and is the most invasive.
- **Keep pre-evaluated flake injection (`mkKitConfigsDynamic`) and add only home-level overrides.**
  Least code, but roots stay baked at flake-eval time and `toolcfg` is not realized.
- **T3 — expose `toolcfg` as a fully independent HM namespace with its own resolver.**
  Most explicit, but adds a second root namespace and duplicates resolution the toolconfig already does.
- **Chosen — hybrid:** `toolcfg.<name>` whose dynpaths values default to the home's global `dynpaths`, plus an integration-owned `extendWith` for recomputation.

## Related artifacts

- `../nix-dynpaths/README.md` — Roots, mode resolution, `checkedPaths` / `checkerScript`.
- `../nix-dynpaths/dynpaths.toolkit-module.nix` — `dynpaths.roots` + `dynamicConfig.*`; source of the mode↔`tryEnable` mapping.
- `../nix-dynpaths/dynpaths.nix`, `../nix-dynpaths/roots-resolver.nix` — generic HM `dynpaths` module and resolver.
- `nix/kits/kit-modules/toolkit-base.kit-module.nix` — `outputs.homeModules.{withDefaults,specific}` options.
- `nix/kits/toolkit-modules/{tmux,nvim,zsh}kit-base.toolkit-module.nix` — current install modules and consumed outputs.
- `nix/kit-system/default.nix` — `defineEval` and `lib.extendWith`.
- `nix/DESIGN_config_system.md` — kit / module / config concepts.
- Consumers: `nix/homes/frametop-bew/cli-core.nix`, `nix/presets/home/cli-neovim.nix`, `nix/homes/work-mac/default.nix`, `nix/homes/frametop-bew/gui.nix`.

## Global Open Questions

- **Terminology & Key Concepts** — omitted per user decision.
  The names `toolconfigs` (flake output), `toolconfigsForImports`, `toolcfg` (HM namespace), and `outs` are handled inline where first used.
- **Naming & IDs** — omitted per user decision.
  Namespace casing and per-tool key shape are covered in Interface / How to use.
- **Design options — T3 vs hybrid** — omitted per user decision.
  The hybrid-vs-pure-T3 choice is covered in Part 1 (Hybrid defaults) and Alternatives & Tradeoffs.
