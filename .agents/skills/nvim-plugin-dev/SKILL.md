---
name: nvim-plugin-dev
description: |
  Neovim plugin authoring for this repo: package layout under `nvim-myplugins/`, module API,
  per-plugin Lua root marker, and loading into the config.
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
- Expose `M.default_config` and `M.setup(given_cfg)` when the plugin is configurable.
- Merge with:
  - `vim.tbl_deep_extend("force", M.default_config, given_cfg or {})` when config nests.
  - `vim.tbl_extend("force", …)` when it is flat.
- Behaviour hooks are functions, not flags — pass a context table
  (`filter(item, bufnr)`, `enable_when(ctx)`, `after_fn(ctx)`).
- Keep config in a module-local `local config` assigned in `M.setup`.
- Never mutate `M.default_config`.
- Public functions carry the plugin's verbs (`M.show`, `M.toggle_zoom`, `M.create_session`).
- Add a short alias when a name is long and used often (`M.get = M.get_session`).
- Expose `M._state` (the module's state table) so tests can inspect or reset it.
- Type config and contexts with `---@class <ns>.Config` / `---@alias <ns>.<Name>`
  (syntax owned by `coder-lua`; here only the naming + placement convention).
- Put shared `---@class`/`---@alias` in `lua/<ns>/types.lua` when they span modules;
  it may be an empty placeholder until needed.
- Keep module state in a plain Lua table owned by the module (or a `*_state_manager`).
  NOTE: values stored in `vim.t`/`vim.g` lose metatables — keep rich objects in Lua state.

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

- Declare it and call `setup` like any other local plugin.
- See the `coder-lua-for-nvim` skill for the declaration and mapping conventions.

## Scaffolding script

- `scripts/scaffold-plugin <name>` creates `<plugins-root>/<name>.nvim/` with `lua/<name>.lua`,
  `stylua.toml`, and `tests/`.
- `<plugins-root>` defaults to `$NVIM_BEW_MYPLUGINS_PATH`; override with `-d <path>`.
- A trailing `.nvim` on `<name>` is stripped; the plugins root is created if missing.
- Errors if the plugin dir already exists.
- Resolve the script path to absolute before invoking it from elsewhere.

## Workflow

1. **Scaffold** — `scripts/scaffold-plugin <name>`, or copy the layout by hand.
2. **Implement** — fill `lua/<name>.lua` (or split into `lua/<name>/`); keep the `M` surface small.
3. **Test** — no settled convention yet; add tests under `tests/` only if useful (see Testing).
4. **Wire** — declare and set up in the config (see Loading into the config).

Pre-done checklist:

- `stylua.toml` root marker present.
- `M.setup` merges config without mutating `M.default_config`.
- Public API and any alias documented per `coder-lua`.
- Tests, if any, pass; otherwise note why none exist (see Testing).
- Plugin declared and set up in the config.
