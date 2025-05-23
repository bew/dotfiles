

## Configuration System Design: Kit, Module, Preset, Profile, Config

**Brainstorming:**
https://www.perplexity.ai/search/suggest-names-i-need-a-set-of-fv7flY7tRjeo1c.9JRnpPw?3=d

---

## Concepts

TL;DR:
- **Kit**: a module system for a specific use-case
- **Module**: a low-level building block for a _kit_, with options decl/impl on a topic
- **Preset**: use _modules_ and set options with preset values on a specific topic
- **Profile**: a larger _preset_, focused on whole use-case
- **Config**: an evaluation of a full module system config

> [!NOTE]
> Technically _modules_, _presets_ & _profiles_ are all **Modules** in the Nix module system terminology.
> But we make these distinctions to semantically separate declaration vs various uses.


### Kit

A **Kit** is basically a module system for a specific use-case.

It is defined with an attrset, here is an example for the NixOS kit:
```nix
{ self, kitsys }:
{
  meta.name = "NixOS kit";
  baseModules = [];
  eval = { lib, ... }: lib.nixosSystem { .. };
}
```

The _kit_'s `eval` function should output an attrset (the final config), with `lib.extendWith` and `lib.extendWithPrevConfig` functions to re-evaluate the current _kit_ with an additional module to
tweak/refine the config with more options/_presets_/_modules_ if needed (can be chained!).

Exposed in a flake as `kit.forMYTECH` (e.g. `kit.forNixOS`)

Example:
- the NixOS module system
- the NixVim module system
- my Zsh config module system, which uses my _tool-kit_ module system


### Module

A **Module** is the low-level building block for a _kit_.
It contains options declaration/implementation on a specific topic.

Exposed in a flake as `kitModules.forMYTECH.MYMODULE`
(e.g. `kitModules.forNixOS.hello-world`)

Examples:
- A NixOS module for `nginx` or `postgresql`.
- A Zsh module for defining _aliases_ or setting _keybinds_.


### Preset

A **Preset** is a partial configuration of module options for a specific _Kit_.

They are partial configurations, focusing on a specific feature.
They may expose a few specific options for their implementation of that feature.

% Example:
Optional modules that can be imported in an OS configuration to add packages / enable some features from the builtin modules / ..


### Profile

A **Profile** is a big _preset_, some profiles may be used directly (without tweaks) to build a
full _config_.

They can combine smaller presets or define some simple options that don't really make sense to separate in presets.

- It references the kit and combines presets (and/or custom values) into a full setup.
- Profiles are user- or environment-specific.
- Each profile is a single, ready-to-use configuration instance.

Example: `dev-workstation.nix` would combine presets and simple options for a developer workstation.


### Configs

A **Config** is the evaluation of a *_kit_* with all its _modules_, _presets_, and _profiles_ applied.
It represents the final, concrete configuration ready for use.

Unlike a _profile_, which is a reusable and composable definition, a _config_ is fully concrete, tailored to a specific environment, user, system..

> [!NOTE]
> Concrete _configs_ created from a _kit_ have `lib.extendWith` and `lib.extendWithPrevConfig` functions, allowing them to be re-evaluated with additional options if needed.
> This will output a new _config_. (can be chained)

Examples:
- A NixOS system configuration generated by combining a workstation profile with custom options.
- A Neovim configuration built from a set of presets for plugins and editor settings.
- A Zsh shell configuration derived from a profile for a developer environment.
