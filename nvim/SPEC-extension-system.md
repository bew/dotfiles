# Extension System Spec

## Introduction

This system provides a structured way to define named integration contracts across a Neovim configuration.
The motivation is that many configuration concerns — highlight group reloading, fuzzy-search selector registration, plugin declaration, key-binding namespaces — need the same plumbing: a place to declare *what* the contract looks like, a place to *implement* it, and many places to *use* it.
Without a formal system, these patterns are reinvented ad hoc each time, using conventions that aren't enforced and can't be introspected.

The Extension System introduces three primitives:

- An **Extension Interface** defines a contract: the extension fields an implementation must handle, the hooks and functions it exposes, and any global configuration options it accepts.
- An **Extension Provider** implements one interface. It receives all registered Extension Point values and provides the runtime behaviour.
- An **Extension Point** is a usage site. It registers values for the fields declared by an interface, which the active Extension Provider then consumes.

Partially inspired by the [NixOS module system](https://nixos.org/manual/nixos/stable/#sec-writing-modules): declarative, composable contracts where modules contribute to a shared schema without needing to know about each other.

Concrete use-cases in this config:
- Declare a highlight-group reloading contract; impl triggers on `ColorScheme` autocmd; every plugin and config section that sets `nvim_set_hl` registers an `on_hl_reload` hook through it.
- Declare a fuzzy-search selector contract; impl wraps telescope; key-binding modules collect all registered selectors and expose them as a picker.
- Declare a plugin-loading contract; impl wraps lazy.nvim; every `Plug {}` call becomes an ExtPoint contributing to the plugin list (see end of spec).

---

## Concepts

**Extension Interface** — the schema.
Declares extension fields with types, defaults, and descriptions.
Can also expose functions (like `boot_plugins`), hooks, events, and global config options.
One active Extension Provider per interface at a time.

**Extension Provider** — the implementation.
Bound to exactly one interface.
Receives aggregated ExtPoint data and drives runtime behaviour.
Only one active per interface; if multi-backend behaviour is needed, use an adapter ExtProvider that delegates internally.

**Extension Point** — the usage site.
Registers values for fields already declared by an interface.
Does *not* declare new fields.
Can reference fields from any interface that has an active ExtProvider.

All three can be defined in any module — one per file, many per file, mixed in plugin files or dedicated modules.

---

## Naming & IDs

Same placeholder pattern as the plugin system:

```lua
Ext.myid { ... }           -- named ExtPoint, ID = "myid"
Ext { id = "myid", ... }   -- equivalent
Ext { ... }                -- anonymous ExtPoint, ID auto-derived
```

Forward references are safe: `Ext.myid` creates a placeholder; `Ext.myid { ... }` fills it in place (same object, same ref).

`ExtInterface` and `ExtProvider` use the same mechanism:

```lua
ExtInterface.hl_groups = Ext.mk_interface(...)
ExtProvider.colorscheme = Ext.mk_provider(ExtInterface.hl_groups, ...)
```

---

## API

### Define interface

```lua
-- A library of pre-defined types helpers (inspired by NixOS modules types)
local ty = require"ext-system.types"

-- Interface definition
ExtInterface.hl_groups = Ext.mk_interface(function(ext, final)
  -- -> 'ext' is a builder obj to build the interface imperatively
  -- -> 'final' is a proxy to the final impl, can be used to define default functions that use
  --    not-yet-implemented (but will be later during use) functions. (FIXME: actually useful?)

  ext:extension_field("define_hl_groups", {
    desc = "Function to define "
    -- Simple type would only check that it's a function at usage-time
    type = ty.Func,
    -- More defined types can be used to check the impl gives correct data at runtime
    type = ty.Func({ ty.Record })
    default = ty.func.default_no_op
  })
  -- Alternative:
  -- a hook is a set of extension fields, pre configured for hooks
  ext:extension_hook("on_hl_reload", { ... })

  -- expose a plain function (not for the ExtPoint)
  ext:expose_function("hello", function()
    print("default hello")
  end)

  -- expose a typed action if the action subsystem is defined
  if ext.expose_action then
    ext:expose_action("ReloadColors", { ty.Func })
  end
end)
```

### Define ExtProvider

```lua
-- (NOTE: I'm not sure yet about this)
--
-- IDEA: Maybe the provider thing isn't always needed,
--   I could use the raw functions to collect config fields from every extension points and skip the complexity of interface/provider..
--   But I still need a way to define the interface (simpler one?)
local provider = Ext.mk_provider(ExtInterface.hl_groups, {
  short_name = "Colors reloader",
  desc = "Reload highlights on ColorScheme change/init",
  impl = function(P, I, final)
    -- -> 'P' is the provider, with all declarations but no impl
    --    Adding new 'things' here is not available here (🤔).
    --    FIXME: how to expose provider-specific stuff? 🤔
    -- -> 'I' is the interface spec, used to retrieve specific fields across all ExtPoints,
    --    without using stringly-typed field names.

    function P.functions:reload_colors()
      self.state.reload_counter = self.state.reload_counter + 1
      local hl_cache = self.state.hl_cache

      local hooks = Ext:collect_values(I.hooks.on_hl_reload)
      hooks:run_pre_all()
      for _, hook in ipairs(hooks) do
        hook.run()
      end
      hooks:run_post_all()
    end

    local function P:init()
      self.state = {
        reload_counter = 1,
        hl_cache = {}
      }
      self.ns -- each provider gets a namespace ID to isolate its stuff
      self.augroup_id -- same

      -- define augroup
      vim.api.nvim_create_autocmd({"ColorScheme"}, {
        group = self.augroup_id,
        callback = final:reload_colors,
      })
    end
  end,
})
```

### Activate ExtProvider

```lua
ExtInterface.hl_groups:use_impl provider
```

### Register ExtPoint

```lua
Ext {
  -- ...
  define_hl_groups = function(hl)
    hl.set("MyHighlightGroup", { bg = "blue", bold = true })
  end,
}
```

---

## Interface Definition & Static Typing

Interface defined imperatively (builder pattern) — no static type info available at edit time.
Editor LSP sees `ext:extension_field(...)` calls but can't derive the resulting schema for ExtPoint authors.

Mitigation: **LuaCATS annotation cache**.
When interface definition changes, a code-gen step re-emits a `.lua` file with `---@class`, `---@field`, etc. annotations derived from `ext:extension_field` calls.
This file is committed alongside the imperative definition.
ExtPoint authors get autocompletion & type-checking from the cached annotations; cache is invalidated + regenerated when the interface changes.

This is opt-in per interface.
Interfaces that change rarely benefit most.

---

## Late Binding

Everything resolves at boot, not at declaration time.
Order of operations does not constrain where things are defined:

- ExtPoint can be declared before its interface has an active ExtProvider.
- ExtProvider can be declared before its interface exists.
- `ExtInterface.foo:use_impl provider` can appear before or after ExtPoints register.

ExtPoints collect values eagerly; the ExtProvider processes them at activation or at a defined lifecycle hook (e.g. `P:init()`).

---

## ExtPoint: Registration, Not Declaration

ExtPoint does NOT add new fields to an interface.
It only supplies values for fields already declared by the interface.
Supplying an unknown field is a runtime error (checked against the interface schema at registration time if the interface is already resolved, or deferred to activation).

ExtPoint can register values for an interface that has no active ExtProvider.
The values are not collected — there is no impl to collect them.
However, if the interface defines a default impl for some fields that does collect, those fields can still be collected via that default impl.
If no ExtProvider is activated before boot completes, the system emits a log entry listing the ExtPoint, the interface, and the fields it supplied that went uncollected.

An ExtPoint can register values for multiple interfaces simultaneously with no restriction.
Each field is matched against the declared fields of each interface independently.

### ExtPoint scopes

It may be useful to define "scopes" of ExtPoint that restrict which interfaces they can register values for.
For example, a `PlugExt` scope might only allow interfaces tagged with a specific group (e.g. `group = "plugin"`), preventing unrelated interfaces from being used in plugin files by mistake.
This scoping could be expressed via interface groups: a scope declares which groups it allows, and registration of a field from an out-of-group interface is a runtime error (or warning).
This is an open design area — see Open Questions.

### Provenance

When an ExtProvider collects values across ExtPoints via `Ext:collect_values(...)`, each entry carries provenance metadata alongside the value:

```lua
-- Each entry in the collected list looks like:
{
  value    = <the actual field value>,
  extpoint = <reference to the ExtPoint object>,  -- extpoint.id gives the ID
  source   = "lua/mycfg/plugs/ui.lua:42"          -- file + line where ExtPoint was declared
}
```

This lets the ExtProvider surface actionable info: e.g. log which ExtPoint's `on_hl_reload` hook raised an error, or expose a `:ExtDebug` command showing each interface's active ExtProvider and which ExtPoints contribute to it.

### Function values & ExtPoint self-reference

When an ExtPoint registers a function as the value of an extension field, the function receives the ExtPoint instance as its first parameter.
This gives the function access to the ExtPoint's identity and state (if any), without closing over it manually:

```lua
Ext {
  on_hl_reload = function(self, ...)
    -- 'self' is the ExtPoint instance
    -- 'self.state' if the ExtPoint has state
    vim.api.nvim_set_hl(0, "MyGroup", { ... })
  end,
}
```

How an ExtProvider passes additional arguments beyond `self` (e.g. a context table, a reload reason) is not yet defined.
Options include: fixed extra params after `self`, a single context table as second param, or a calling convention declared on the extension field type.
This needs further design — see Open Questions.

---

## Placement

Any of ExtInterface / ExtProvider / ExtPoint can be defined anywhere: dedicated module, inside a plugin file, scattered across config.
No required directory structure or load order — late binding handles it.

---

## Plug as ExtPoint (future)

`Plug { ... }` can be redefined as an ExtPoint once this system is stable:

```lua
-- Interface declares all plugin fields: source, on_load, tags, depends_on, ...
-- ExtProvider is the lazy.nvim adapter
ExtInterface.plugin:use_impl ExtProvider.lazy_nvim

-- Plug becomes a thin wrapper that registers an ExtPoint
local function Plug(spec)
  return Ext { interface = ExtInterface.plugin, ... } -- merges spec
end
```

`ExtInterface.plugin` exposes `boot_plugins()` — called from config init, triggers the lazy.nvim boot sequence with all collected ExtPoint specs.

### Package manager bootstrap

The current plugin system has a special-cased `id = "pkg_manager"` ExtPoint that must be found and booted first, before any other plugin can be loaded.
This bootstrapping problem requires the ExtProvider to know which ExtPoint is the pkg manager, and to boot it before activating the rest.

A `pre_boot` hook field on `ExtInterface.plugin` handles this cleanly: the pkg manager ExtPoint registers itself on this hook, and the ExtProvider runs all `pre_boot` hooks before processing the rest of the plugin specs.
Multiple ExtPoints can register a `pre_boot` value without conflict.

---

## Positioning Question: Ext System vs. Plain Lua Module

Worth explicitly questioning whether this system earns its complexity.

**Plain Lua module approach:**
```lua
local HL = require"mycfg.hl_system"
HL.setup({ autocmd = true })
HL.register("MyGroup", function(hl) hl.set(...) end)
-- elsewhere:
HL.reload_all()
```

Advantages: zero framework, full LSP support, simple to understand, easy to debug.

**Ext System advantages:**
- Cross-cutting concerns (hl groups, fuzzy pickers, plugin specs) all use one pattern — new contributors learn one API.
- Interfaces are self-documenting (schema + types) — a plain module's `setup({})` isn't.
- Runtime validation catches wrong field types at registration, not silently at call time.
- ExtPoints can be defined before the impl exists — useful for configs that conditionally activate features.
- The `expose_function` / `expose_action` mechanism gives a standard way to publish callable API from a subsystem.

**Ext System costs:**
- Indirection: to understand what `Ext { define_hl_groups = ... }` does, you must find `ExtInterface.hl_groups`, then find the ExtProvider, then follow `Ext:collect_values`. Three hops vs. one `rg HL.register`.
- No static typing without the LuaCATS cache mechanism.
- Debugging a misbehaving ExtProvider requires understanding the framework, not just the domain.

**Rough heuristic:** use the Ext System when a contract has 3+ independent usage sites that need to stay decoupled.
Use a plain module when it's 1-2 callers and the impl is stable.

---

## Open Questions

1. **ExtProvider-specific exposure** — how does an ExtProvider expose things (functions, state) that aren't part of the interface contract?
   e.g. `provider.reload_all()` called from outside.
   Through `ext:expose_function`? Through a separate returned handle?

2. **`final` proxy** — is the `final` arg in `mk_interface` actually useful?
   The use-case (default impls that reference not-yet-bound methods) seems fragile.
   Worth keeping?

3. **ExtPoint scopes & interface groups** — how exactly are groups assigned to interfaces?
   How does an ExtPoint scope declare which groups it allows?
   Is the check a hard error or a warning?
   Can an ExtPoint opt out of scope restrictions for a specific field?

4. **Function value calling convention** — when an ExtProvider calls a collected function value, how are extra args passed beyond the implicit `self` (ExtPoint instance)?
   Options: fixed positional params, a single context table, or a calling convention declared on the field type in `ext:extension_field`.

5. **ExtProvider simplification** — as noted in the code comment: for some interfaces, skipping `mk_provider` entirely and just calling `Ext:collect_values` from a plain function may be simpler.
   Should the system support "interface without formal ExtProvider" as a first-class mode?

6. **Ext System bootstrapping** — the Ext System itself needs to be initialized before any interface, ExtProvider, or ExtPoint is declared.
   How this boot phase works (especially in a Neovim config with lazy-loaded modules) is a topic for another day.
