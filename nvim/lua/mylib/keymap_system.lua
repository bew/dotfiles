local U = require"mylib.utils"
local _f = U.fmt.str_space_concat
local _q = U.fmt.str_simple_quote_surround

local A = require"mylib.action_system"

local K = {}

---@class keysys.MapSpec
---@field mode string|string[] Mode(s) for which to map the key
---@field key string Key to map
---@field action act.MultiModeAction|act.RawModeAction Action to assign to key
---@field desc? string Keymap description
---@field opts? table Keymap options (same as for `vim.keymap.set`).
---    When action is an Action obj, opts must not conflict.
---@field debug? boolean Whether to print debugging info about the keymap

---@class keysys.MapGroupSpec
---@field name string Group name (e.g. prefixed with `+`)
---@field mode string|string[] Mode(s) the group is for
---@field prefix_key string Common group prefix key

---@alias keysys.MapperFn fun(mode: string|string[], key: string, action: act.RawModeAction, opts?: vim.keymap.set.Opts)

--- Normalize mode `v` to always mean `x` (visual mode ONLY instead of both visual/select)
---@param mode string
---@return string
-- 👉 Always replace `v` by `x`, so `v` is ONLY visual mode instead of both visual/select
-- (ref: `:h mapmode-x`)
local function normalize_mode(mode)
  if mode == "v" then
    return "x"
  else
    return mode
  end
end

---@param map_spec keysys.MapSpec
---@param mapper keysys.MapperFn
function K.register_map(map_spec, mapper)
  vim.validate("mode", map_spec.mode, {"string", "table"})
  vim.validate("key", map_spec.key, "string")
  vim.validate("action", map_spec.action, function(a)
    if vim.tbl_contains({"function", "string"}, type(a)) then
      return true
    end
    return type(a) == "table" and a.meta.action_version == "v2"
  end)
  vim.validate("opts", map_spec.opts, "table", true) -- optional
  vim.validate("debug", map_spec.debug, "boolean", true) -- optional

  ---@type string[]
  local map_modes = U.args.normalize_arg_one_or_more(map_spec.mode)

  -- When the action is not an action obj, transform it quickly to a cheap action v2:
  local map_action ---@type act.MultiModeAction
  if type(map_spec.action) ~= "table" then
    map_action = A.mk_action {
      default_desc = tostring(map_spec.action),
      ---@diagnostic disable-next-line: assign-type-mismatch (we know the type is right)
      [map_modes] = map_spec.action, ---@type act.RawModeAction
    }
  else
    ---@diagnostic disable-next-line: assign-type-mismatch (we know the type is right)
    map_action = map_spec.action ---@type act.MultiModeAction
  end
  -- map_action is now guaranteed to be an action object

  -- Check the action supports all requested modes
  if not map_action:supports_modes(map_modes) then
    print(vim.inspect(map_action))
    error(_f("Action does not support all given modes:", vim.inspect(map_modes)))
  end

  -- For each mode...
  for _, mode in ipairs(map_modes) do
    local mode_action = map_action:get_mode_action(mode)
    assert(mode_action, _f("action missing for mode", _q(mode)))

    -- Options
    -- note: map_opts set at action-level are required, make sure the given opts don't conflict
    local map_opts = vim.tbl_extend("error", map_spec.opts or {}, mode_action.map_opts or {})
    -- Description
    local description = map_spec.desc or mode_action.default_desc
    if description then
      map_opts.desc = description
    end

    -- Ensure `v` mode means visual ONLY (replace `v` with `x`)
    local normalized_mode = normalize_mode(mode)
    if map_spec.debug or mode_action.debug or false then
      print(
        "Debugging keymap (action):",
        "mode:", vim.inspect(mode) .. " (normalized: " .. vim.inspect(normalized_mode) .. ")",
        "key:", vim.inspect(map_spec.key),
        "raw-action:", vim.inspect(mode_action.raw_action),
        "auto-overrides:", vim.inspect(mode_action.auto_overrides),
        "opts:", vim.inspect(map_opts, { newline = " ", indent = "" })
      )
    end

    mapper(normalized_mode, map_spec.key, mode_action:get_action_for_keymap(), map_opts)
  end
end

--- Define map group for which_key plugin
---@diagnostic disable-next-line: lowercase-global
wk_groups_lazy = {}

--- Define a (global) <leader> map group
---@param spec keysys.MapGroupSpec
function K.toplevel_map_define_group(spec)
  assert(spec.name, "group name is required")
  assert(spec.mode, "mode is required")
  ---@type string[]
  local modes = U.args.normalize_arg_one_or_more(spec.mode)
  local group_wk_spec = {
    spec.prefix_key,
    group = spec.name,
    mode = vim.tbl_map(normalize_mode, modes),
    hidden = spec.name == "__hide__",
  }
  -- NOTE: if which-key can be loaded, use it, otherwise register the group spec for later
  local success, wk = pcall(require, "which-key")
  if success then
    wk.add { group_wk_spec }
  else
    table.insert(wk_groups_lazy, group_wk_spec)
  end
end

--- Create (top-level) key mapping
---@param map_spec keysys.MapSpec
function K.toplevel_map(map_spec)
  K.register_map(map_spec, vim.keymap.set)
end
--- Create remap-enabled (top-level) map
---@param spec keysys.MapSpec
function K.toplevel_remap(spec)
  spec.opts = spec.opts or {}
  spec.opts.remap = true
  K.toplevel_map(spec)
end
--- Create buf-specific (top-level) map
---@param spec keysys.MapSpec
function K.toplevel_buf_map(spec)
  spec.opts = spec.opts or {}
  spec.opts.buffer = true
  K.toplevel_map(spec)
end


--- Create (global) <leader> key mapping
---@param spec keysys.MapSpec
function K.global_leader_map(spec)
  K.toplevel_map(vim.tbl_extend("force", spec, {
    key = "<Leader>"..spec.key,
  }))
end
--- Create remap-enabled (global) <leader> map
---@param spec keysys.MapSpec
function K.global_leader_remap(spec)
  if not spec.opts then
    spec.opts = {}
  end
  spec.opts.remap = true
  K.global_leader_map(spec)
end
--- Define a (global) <leader> map group
---@param spec keysys.MapGroupSpec
function K.global_leader_map_define_group(spec)
  spec.prefix_key = "<Leader>"..spec.prefix_key
  K.toplevel_map_define_group(spec)
end

----

--- Create (content-related) <localleader> key mapping
---@param spec keysys.MapSpec
function K.local_leader_map(spec)
  K.toplevel_map(vim.tbl_extend("force", spec, {
    key = "<LocalLeader>"..spec.key,
  }))
end
--- Create remap-enabled (content-related) <localleader> map
---@param spec keysys.MapSpec
function K.local_leader_remap(spec)
  spec.opts = spec.opts or {}
  spec.opts.remap = true
  K.local_leader_map(spec)
end
--- Create buf-specific (content-related) <localleader> map
---@param spec keysys.MapSpec
function K.local_leader_buf_map(spec)
  spec.opts = spec.opts or {}
  spec.opts.buffer = true
  K.local_leader_map(spec)
end
--- Define a (content-related) <localleader> map group
---@param spec keysys.MapGroupSpec
function K.local_leader_map_define_group(spec)
  spec.prefix_key = "<LocalLeader>"..spec.prefix_key
  K.toplevel_map_define_group(spec)
end


return K
