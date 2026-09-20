---
name: nvim-plugin-dev
description: |
  Neovim plugin authoring for this repo: package layout under `nvim-myplugins/`, module API,
  actions & config, autocmds, per-plugin Lua root marker, and loading into the config.
  Always load when asked to draft/write/edit/refactor/review a `nvim-myplugins/*.nvim` plugin.
  Requires coder-generic, coder-lua, and coder-lua-for-nvim skills.
metadata:
  maintainers: [bew]
---

## Goal

Author small personal Neovim plugins under `nvim-myplugins/` as reusable Lua packages,
building on generic & Lua conventions.

REQUIRES: load `coder-generic`, `coder-lua`, and `coder-lua-for-nvim` skills first.

This skill covers the plugin **package** only.
Every file is a Lua module — loaded via `require`, no script code.
Plugin packages live in `nvim-myplugins/<name>.nvim/`, outside `nvim/lua/**`.
Config conventions for `nvim/lua/**` stay in `coder-lua-for-nvim`; do not restate them here.

## Package layout

- One directory per plugin: `nvim-myplugins/<name>.nvim/`.
- Module namespace = plugin name minus `.nvim` (`smart-bol.nvim` → `require"smart-bol"`).
- Required tree:
  ```text
  <name>.nvim/
  ├── lua/
  │   ├── <name>.lua          # single-file plugin
  │   └── <name>/             # or multi-file split
  │       ├── init.lua
  │       └── <submodule>.lua
  ├── stylua.toml             # mandatory, see Lua root marker
  └── tests/                  # optional, see Testing
  ```

- Single file when the plugin is small (`content-overview.nvim`, `restore-cursor.nvim`).
- Split into `lua/<name>/init.lua` + submodules when there is state, types, or reusable helpers.
  Observed split roles: `core` (pure logic), `actions` (vim-mutating), `utils` (shared helpers),
  `types` (annotations only), `*_state_manager`, `*_indicator`.
- `init.lua` is the public entry; submodules are `require"<ns>.<submodule>"`.

## Module API

- `local M = {}` … `return M` (see `coder-lua`).
- Expose `M.default_config` and a config mechanism when the plugin is configurable
  (see Plugin options & config).
- Behaviour hooks are functions, not flags — pass a context table
  (`filter(item, bufnr)`, `enable_when(ctx)`, `after_fn(ctx)`).
- Public functions carry the plugin's verbs (`M.show`, `M.toggle_zoom`, `M.create_session`).
- Add a short alias when a name is long and used often (`M.get = M.get_session`).
- Expose `M._state` (the module's state table) so tests can inspect or reset it.
- Type setter input as `<ns>.Opts.UserConfig`, resolved config as `<ns>.Config`, and contexts as
  `---@class <ns>.<CtxName>` (e.g. `<ns>.OnAttachCtx`); syntax owned by `coder-lua`, here only the
  naming + placement convention.
- Put shared `---@class`/`---@alias` in `lua/<ns>/types.lua` when they span modules;
  it may be an empty placeholder until needed.
- Keep module state in a plain Lua table owned by the module (or a `*_state_manager`).
  NOTE: values stored in `vim.t`/`vim.g` lose metatables — keep rich objects in Lua state.
- Never define keymaps from the plugin (not even buffer-local).
  Expose action functions and let the user map them in their config (see Exposing actions & API).

## Plugin options & config

Configuration mechanisms; pick per plugin in the design phase:
- `M.setup(opts)` (or `configure(opts)`) — configuration only, no initialization side effects
  (`:h lua-plugin-init`).
  Prefer it when the config already `require`s the plugin (this repo's `on_load` wiring) or when
  initialization depends on the options.
- A global table `vim.g.<ns>` — the user configures without loading the plugin, and the plugin reads
  it lazily at first use (`:h lua-plugin-config`).
  Prefer it for `plugin/`-auto-loaded plugins to avoid an eager `require` at startup.
  Treat it as read-only config, not mutable state, and note it is harder to validate.

Type the setter input and resolved config separately:
- `<ns>.Opts.UserConfig` — what the setter accepts; every field optional.
  A config setter's `opts` (e.g. `setup(opts)`) is a function named-params structure, so it
  belongs under `Opts`.
- `<ns>.Config` — the resolved internal config; every field required after defaults are merged.

Merge defaults with `vim.tbl_deep_extend("force", M.default_config, given or {})` (or
`vim.tbl_extend` when flat), keep the result in a module-local, and never mutate `M.default_config`.
Expose `M.get_config()` returning a copy of the resolved config for introspection.

TODO: validation is not settled — `vim.validate()` for types and a `:checkhealth` check for
unknown/misspelled keys are the intended direction (`:h lua-plugin-config`).

## Exposing actions & API

- Split the plugin surface into namespaces:
  - `api` — low-level functions for custom user needs (`<ns>.api.<fn>`).
    A simple plugin may have none.
  - `actions` — user-facing actions (`<ns>.actions.<verb>`); may be re-exported at the module
    root if the plugin is small.
- Decide the exact split in the plugin design phase, not ad hoc.
- These plugin actions are plain functions — they are NOT the config action system
  (`A.mk_action`), and there is no reusable plugin-action framework yet; do not pretend otherwise.

## Defining actions

- An action is a plain function under the `actions` namespace, named with a verb
  (`actions.toggle_messages`, `actions.goto_next_marker`).
- Keep each action small and focused; move shared logic into `api` or a helper module.
- Document each action per `coder-lua` (summary line + params/return).
- TODO: finalize the shared action signature (context argument, return value) as usage grows.

## `plugin/` directory

- A `plugin/<name>.lua` file runs at startup and is the only auto-activated code.
  Reserve it for:
  - user commands (`nvim_create_user_command`),
  - autocmds that MUST be globally active without config (`:h lua-plugin-new`).
- Keep it tiny and defer `require` into the command/mapping callback
  (`:h lua-plugin-defer-require`).
- Do NOT use `<Plug>` mappings as the extension mechanism — expose Lua functions instead
  (`:h lua-plugin-keymaps`).

## Autocmds

- For autocmds that are dynamic or need config, do not put them in `plugin/`.
  Create them in the module, inside a plugin-specific augroup:
  `vim.api.nvim_create_augroup("<Name>", { clear = true })`.
- Clear the augroup on init and keep its id in the plugin's state (or a module-local).

## Buffer-local mappings

- Buffer-local maps are tricky: the map needs the target buffer to exist, and the user config
  needs that buffer's `bufnr` to place it. So the plugin must not map itself.
- Expose a config hook that the plugin calls right after it creates the buffer:
  - `on_attach` when there is a single target buffer kind,
  - `on_<role>_attach` when there is more than one (e.g. `on_sidepanel_attach`).
- Pass a typed context (e.g. `---@class <ns>.OnAttachCtx`) with at least a `bufnr` field, so the
  user config can define proper buffer-local maps for that buffer.

## Lua root marker

- Every plugin ships its own `stylua.toml` with exactly:
  ```toml
  # (NOTE: The file is used to find root of a Lua project, to avoid loading too much)
  # Reference: https://github.com/JohnnyMorganz/StyLua
  indent_type = "Spaces"
  indent_width = 2
  call_parentheses = "Input"
  ```

- The file is a root marker only: the Lua LSP uses it to stop ascending and treat the
  plugin dir as the project root. It is not used as a formatter config here.
- One copy per plugin.

## Testing

No plugin test convention is settled yet — treat this section as TBD.

- Put tests under `tests/` when a plugin needs them.
- For ad-hoc module-level headless checks, defer to `coder-lua-for-nvim`.

## Comments & docs

- Start the entry file with a header comment stating the plugin's purpose in one or two lines.
- Record *why* for non-obvious vim behaviour, and link the upstream issue/PR that motivated it
  (see `restore-cursor.nvim`).
- Mark open work inline: `FIXME:` (known bug), `TODO:` (planned), `IDEA:` (possible improvement).
- Function docs, parameter/return contracts, and LuaCATS syntax are owned by
  `coder-generic` and `coder-lua` — do not restate them.

## Loading into the config

A plugin under `nvim-myplugins/` is inert until declared and set up in the config.

- Declare it, then configure it per its mechanism: call `setup(opts)` in `on_load`, or assign the
  `vim.g.<ns>` table (see Plugin options & config).
- See the `coder-lua-for-nvim` skill for the declaration and mapping conventions.

## Scaffolding script

- `scripts/scaffold-plugin <name>` creates `<plugins-root>/<name>.nvim/` with `lua/<name>.lua`,
  `stylua.toml`, and `tests/`.
- `<plugins-root>` defaults to `$NVIM_BEW_MYPLUGINS_PATH`; override with `-d <path>`.
- A trailing `.nvim` on `<name>` is stripped; the plugins root is created if missing.
- Errors if the plugin dir already exists.
- Resolve the script path to absolute before invoking it from elsewhere.

## Plugin design phase

Before writing code, run a design phase and ask the user (use the question tool):
- What is the plugin's purpose and its minimal public surface?
- Which functions are `actions` (user-facing) vs `api` (low-level)?
- Which entrypoints exist: commands, autocmds, none?
- How does it load: eagerly via `plugin/`, or lazily via config `setup`?
- Which config mechanism fits: `M.setup(opts)` or a `vim.g.<ns>` table?

Do not start implementing until these are answered.

## Workflow

0. **Design** — run the plugin design phase above and get user answers.
1. **Scaffold** — `scripts/scaffold-plugin <name>`, or copy the layout by hand.
2. **Implement** — fill `lua/<name>.lua` (or split into `lua/<name>/`); keep the `M` surface small.
3. **Test** — no settled convention yet; add tests under `tests/` only if useful (see Testing).
4. **Wire** — declare and set up in the config (see Loading into the config).

Pre-done checklist:
- `stylua.toml` root marker present.
- Config setter merges defaults without mutating `M.default_config`; `M.get_config()` returns the
  resolved copy.
- Public API and any alias documented per `coder-lua`.
- No keymaps defined by the plugin; actions exposed as functions.
- Dynamic autocmds live in a plugin-specific augroup.
- Tests, if any, pass; otherwise note why none exist (see Testing).
- Plugin declared and set up in the config.
