-- FIXME: &rtp and &pp defaults to loaaads of stuff on NixOS, using the
-- maannyyyy dirs from XDG_CONFIG_DIRS & XDG_DATA_DIRS...
-- => Remove the ones from these folders that don't actually exist?

-- TODO: re-enable, and contribute fixes to all plugins with undefined global vars..
--_G = setmetatable(_G, {
--  __index = function(_, key)
--    error("Unknown global variable '" .. key .. "'")
--  end,
--})

-- Load options early in case the initialization of some plugin requires them.
-- (e.g: for filetype on)
require"mycfg.options"

-- NOTE: If trying to move it AFTER plugin load, double check git signs are of correct color!
vim.cmd[[ colorscheme bew256-dark ]]
vim.opt.termguicolors = false -- TODO: convert my theme to RGB!

-- Map leaders
-- NOTE: Special termcode (like `<foo>`) must be replaced to avoid _very_ unexpected behavior
--   See: https://github.com/neovim/neovim/issues/27826 😬
vim.g.mapleader = vim.api.nvim_replace_termcodes([[<C-Space>]], true, true, true)
vim.g.maplocalleader = vim.api.nvim_replace_termcodes([[<Space>]], true, true, true)
-- IDEA: Change <Leader> to <C-space> | Have <localleader> be <space>
-- And the CtrlSpace plugin would be <Leader><Space> or <Leader><Leader>
-- Also give a new leader possibility with <Alt-Space> (for a command center?) (:

local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

-- Mapping helpers
-- TODO: move them to a dedicated module!

-- Create initial leader maps (to be used in init of some plugins)
wk_toplevel_n_maps = {}
wk_toplevel_v_maps = {}

--- Get the which_key's <group> map for the given mode
function get_wk_maps_for_mode(mode)
  local wk_toplevel_maps_for_mode = {
    n = wk_toplevel_n_maps,
    v = wk_toplevel_v_maps,
  }
  return wk_toplevel_maps_for_mode[mode]
end

--- Define map group for which_key plugin
function toplevel_map_define_group(spec)
  assert(spec.mode, "mode is required")
  local group_name = spec.name ~= "__hide__" and spec.name or "which_key_ignore"
  for _, m in ipairs(spec.mode) do
    local wk_maps = get_wk_maps_for_mode(m)
    if wk_maps then
      wk_maps[spec.prefix_key] = { name = group_name }
    end
  end
end

function toplevel_buf_map(map_spec)
  map_spec.opts = map_spec.opts or {}
  map_spec.opts.buffer = true
  toplevel_map(map_spec)
end

-- Normalize mode `v` to always mean `x` (visual mode ONLY instead of both visual/select)
-- ⚠️⚠️ Prevent mapping to both visual & select mode with `v`
-- 👉 Always replace `v` by `x` so `v` is ONLY visual mode instead of both visual/select
-- (ref: `:h mapmode-x`)
local function normalize_mode(mode)
  if mode == "v" then
    return "x"
  else
    return mode
  end
end

--- Create top level maps
---@param map_spec.mode string|{string} Mode(s) for which to map the key
---@param map_spec.key string Key to map
---@param map_spec.action ActionV2|ModeActionSpecInput|ModeRawActionInput Action to assign to key
---@param map_spec.opts table Keymap options (same as for `vim.keymap.set`). When map_spec.action is
---   an ActionV2 obj, opts must not conflict.
---@param map_spec.debug bool Whether to print debugging info about the keymap
function toplevel_map(map_spec)
  vim.validate{
    mode={map_spec.mode, {"string", "table"}},
    key={map_spec.key, "string"},
    action={
      map_spec.action,
      function(a)
        if vim.tbl_contains({"function", "string"}, type(a)) then
          return true
        end
        return type(a) == "table" and a.meta.action_version == "v2"
      end,
    },
    opts={map_spec.opts, "table", true}, -- optional
    debug={map_spec.debug, "boolean", true}, -- optional
  }
  local debug_keymap = map_spec.debug or false

  local map_modes = U.normalize_arg_one_or_more(map_spec.mode)

  -- When the action is not an action obj, transform it quickly to a cheap action v2:
  if type(map_spec.action) ~= "table" then
    map_spec.action = mk_action_v2 {
      [map_modes] = map_spec.action,
    }
  end
  -- map_spec.action is now guaranteed to be an action v2 object

  -- Check the action supports all requested modes
  if not map_spec.action:supports_mode(map_modes) then
    print(vim.inspect(map_spec.action))
    error(_f("Action does not support all given modes:", vim.inspect(map_modes)))
  end

  for _, mode in ipairs(map_modes) do
    local action_for_mode = map_spec.action.mode_actions[mode]
    assert(action_for_mode, _f("action missing for mode", _q(mode)))

    -- Options
    -- note: map_opts set at action-level are required, make sure the given opts don't conflict
    local map_opts = vim.tbl_extend("error", map_spec.opts or {}, action_for_mode.map_opts or {})
    -- Description
    local description = map_spec.desc or action_for_mode.default_desc
    if description then
      map_opts.desc = description
    end

    -- ⚠️ Ensure `v` mode means visual ONLY (replace `v` with `x`)
    local normalized_mode = normalize_mode(mode)
    if map_spec.debug or action_for_mode.debug or false then
      print(
        "Debugging keymap (action v2):",
        "mode:", vim.inspect(mode) .. " (normalized: " .. vim.inspect(normalized_mode) .. ")",
        "key:", vim.inspect(map_spec.key),
        "raw-action:", vim.inspect(action_for_mode.raw_action),
        "opts:", vim.inspect(map_opts, { newline = " ", indent = "" })
      )
    end

    vim.keymap.set(normalized_mode, map_spec.key, action_for_mode.raw_action, map_opts)
  end
end

--- Create global leader key mapping
function global_leader_map(spec)
  toplevel_map(vim.tbl_extend("force", spec, {
    key = "<Leader>"..spec.key,
  }))
end
--- Helper to create remap-enabled leader map, see `global_leader_map` for details
function global_leader_remap(spec)
  if not spec.opts then
    spec.opts = {}
  end
  spec.opts.remap = true
  global_leader_map(spec)
end
function global_leader_map_define_group(spec)
  spec.prefix_key = "<Leader>"..spec.prefix_key
  toplevel_map_define_group(spec)
end

----

--- Create local (content-related) leader key mapping
-- FIXME: these should be probably only used with <buffer> local keymaps 👀
--   But for that I'd need to setup my plugins to load content-related mappings on file init.. 🤔
function local_leader_map(spec)
  toplevel_map(vim.tbl_extend("force", spec, {
    key = "<LocalLeader>"..spec.key,
  }))
end
function local_leader_remap(spec)
  spec.opts = spec.opts or {}
  spec.opts.remap = true
  local_leader_map(spec)
end
function local_leader_map_define_group(spec)
  spec.prefix_key = "<LocalLeader>"..spec.prefix_key
  toplevel_map_define_group(spec)
end
function local_leader_buf_map(spec)
  spec.opts = spec.opts or {}
  spec.opts.buffer = true
  local_leader_map(spec)
end

-- Minimal action system
--
-- IDEA of a plugin name:
-- - `factions` [short: `fact`]: Framework for Actions
--   BAD: plugin short name `fact` doesn't make me think about actions, but facts which an entirely
--     different thing..
-- - `nactions` [short: `nact`]: Neovim Actions
-- - `spectacle` [short: `acts`]: Like at a spectacle we present only nice interface (nice show),
--   through acts (meaning actions for us, but parts of a play for a spectacle).
-- - Words related to 'somebody/something who does actions':
--   * "performer" (❤ ?)
--   * "actor"
--   * "operator"
--   * "executor"
--   Nice ones!

---@alias ModeRawActionInput string|(fun(): any)

---@class ModeActionSpecInput
---@field raw_action ModeRawActionInput The raw action to execute
---@field default_desc? string The default description for the keymap when this action is used
---@field map_opts? {string: any} The keymap options for that action
---@field debug? boolean Wheather to debug the effective keymap args on use

---@class ActionSpecInput: ModeActionSpecInput (used as defaults for each mode)
---@field n ModeRawActionInput|ModeActionSpecInput Action spec for normal mode
---@field i ModeRawActionInput|ModeActionSpecInput Action spec for insert mode
---@field v ModeRawActionInput|ModeActionSpecInput Action spec for visual mode
---@field o ModeRawActionInput|ModeActionSpecInput Action spec for operator mode
---@field c ModeRawActionInput|ModeActionSpecInput Action spec for command mode
--- + key like `{"n", "i"}` to set both `n` & `i` action spec.

---@class ActionV2
---@field meta Metadata about this action
---@field mode_actions {string: ModeAction} Action for each mode

---@class ModeAction: ModeActionSpecInput

local ActionSpec_mt = {
  __index = setmetatable(
    {
      supports_mode = function(self, given_modes)
        vim.validate { mode={given_modes, {"string", "table"}} }
        local supported_modes = vim.tbl_keys(self.mode_actions)
        for _, mode in ipairs(U.normalize_arg_one_or_more(given_modes)) do
          if not vim.tbl_contains(supported_modes, mode) then
            return false
          end
        end
        return true
      end,

      -- WIP WIP WIP (and untested) functions to enable configurable actions
      --
      -- --- Returns true if the action has configuration options, false otherwise.
      -- is_configurable = function(self)
      --   return type(self.options_def) == "table" and not vim.tbl_isempty(self.options_def)
      -- end,
      --
      -- --- Set given options as the default options for this action from now on.
      -- set_default_opts = function(self, given_opts)
      --   self:_ensure_is_configurable()
      --   self:_validate_given_opts(given_opts)
      --   self.opts = vim.tbl_extend("force", self.opts, given_opts)
      -- end,
      --
      -- --- Duplicate this action with the given options replacing default ones
      -- with_opts = function(self_parent, given_opts)
      --   self:_ensure_is_configurable()
      --   self:_validate_given_opts(given_opts)
      --   local new_action_opts = vim.tbl_extend("keep", given_opts, self_parent.opts)
      --   -- FIXME: make a cheap proxy action with new opts (and good mt) & return that
      --   local proxy_action = {opts = new_action_opts}
      --   -- FIXME: copy self_parent's metatable, and add original action as `__index` metamethod
      --   local self_mt = getmetatable(self_parent)
      --   local proxy_mt = vim.tbl_extend("force", {}, self_mt) -- copy metatable
      --   proxy_mt.__index = self_parent -- if not found in parent, its mt should be triggered
      --   return setmetatable(proxy_action, proxy_mt)
      -- end,
      --
      -- -- Ensure the action is configurable before trying to access/use options
      -- _ensure_is_configurable = function(self)
      --   if not self:is_configurable() then
      --     error("This action is NOT configurable!")
      --   end
      -- end,
      -- -- Validate given_opts has only declared options & values are of valid types.
      -- _validate_given_opts = function(self, given_opts)
      --   for opt_name, new_value in pairs(given_opts) do
      --     if not self.options_def[opt_name] then
      --       error("This action doesn't have option '" .. opt_name .. "'")
      --     end
      --     local opt_spec = self.options_def[opt_name]
      --     if type(new_value) ~= opt_spec.type then
      --       error(_f("Given value for option", _q(opt_name), "has invalid type", _q(type(new_value))))
      --     end
      --   end
      -- end,
    },
    -- FIXME: is there a better/simpler way to chain __index metamethods?
    require"mylib.mt_utils".KeyRefMustExist_mt
  ),
  __call = function(self, ...)
    local nb_mode_actions = #vim.tbl_keys(self.mode_actions)
    if nb_mode_actions ~= 1 then
      error(_f(
        "Ad-hoc action call ONLY supports single mode action, got", nb_mode_actions,
        "(mode(s)", vim.inspect(vim.tbl_keys(self.mode_actions)), ")"
      ))
    end
    local adhoc_action = vim.tbl_values(self.mode_actions)[1]
    adhoc_action(...)
  end
}
local SingleModeActionSpec_mt = {
  __call = function(self, ...)
    if (self.map_opts or {}).expr then
      error("Ad-hoc action call of expr-based action is NOT tested/supported")
    end

    local raw_action_type = type(self.raw_action)
    if raw_action_type == "function" then
      self.raw_action(...)
    elseif raw_action_type == "string" then
      error("Ad-hoc action call of a string raw action is not implemented (failed..)")
      -- FIXME: I can't get it to work properly,
      --   e.g with cmd mode or surround actions..
      ----------------------------------------------------
      -- local feed_keys_opts = {
      --   remap = self.keymap_opts.remap,
      --   replace_keycodes = self.keymap_opts.expr or false,
      -- }
      -- -- if self.debug then
      --   print("Debugging ad-hoc feedkeys:",
      --     "raw_action:", vim.inspect(self.raw_action),
      --     "feed_keys_opts:", vim.inspect(feed_keys_opts),
      --   )
      -- -- end
      -- -- NOTE: assumes termcodes haven't been replaced yet (<C-x>, <Plug>, etc..)
      -- U.feed_keys_sync(self.raw_action, feed_keys_opts)
      -- vim.api.nvim_feedkeys(self.raw_action, feedkeys_mode, replace_keycodes)
    else
      error(_f("Ad-hoc action call with raw action of type", _q(raw_action_type), "is not supported"))
    end
  end,
}

---@type {[string]: ActionSpec}
my_actions = {}

-- Usage:
-- mk_action_v2 {
--   default_desc = "Description for n/i (normal/insert mode) actions"
--
--   n = "zz",
--   -- same as
--   n = {
--     "zz",
--     -- other options for action for normal mode
--   }
--   -- same as
--   n = {
--     raw_action = "zz"
--   }
--   -- technically same as
--   n = {
--     map_opts = { expr = true },
--     raw_action = function() return "zz" end
--   }
--
--   i = {
--     function() return "<Left>" end,
--     map_opts = { expr = true },
--   }
--
--   v = {
--     default_desc = "Description for visual mode action"
--     "zf"
--     map_opts = { silent = true },
--   }
-- }
function mk_action_v2(global_spec)
  -- For a given mode, I want these fields:
  -- - default_desc
  -- - raw_action
  -- - map_opts
  -- - debug
  -- If field not given (except for `raw_action`), use the field at parent level (for all modes) if any

  local function mk_action_single_mode(mode_spec)
    -- (note: uses upvalue 'global_spec')
    if type(mode_spec) == "function" or type(mode_spec) == "string" then
      mode_spec = { raw_action = mode_spec }
    end
    if type(mode_spec) ~= "table" then
      error(_f("spec for mode must be a function, a string or a mode spec, got", _q(type(mode_spec))))
    end
    -- Allow raw_action to be given without the key, as first item of a table list
    -- => `n = { "foo" }` is same as `n = { raw_action = "foo" }`
    if mode_spec.raw_action == nil then
      if mode_spec[1] ~= nil then
        mode_spec.raw_action = mode_spec[1]
      else
        error("Missing action!")
      end
    end
    local mode_action = {
      raw_action = mode_spec.raw_action,
      default_desc = mode_spec.default_desc or global_spec.default_desc,
      map_opts = mode_spec.map_opts or global_spec.map_opts,
      debug = mode_spec.debug or global_spec.debug,
    }
    return setmetatable(mode_action, SingleModeActionSpec_mt)
  end

  local VALID_MODES_FOR_ACTIONS = {"n", "i", "v", "x", "o", "c", "s"}

  -- Find all action specs for each valid mode
  local spec_for_mode = {}
  for maybe_mode, value in pairs(global_spec) do
    if type(maybe_mode) == "string" then
      if vim.tbl_contains(VALID_MODES_FOR_ACTIONS, maybe_mode) then
        spec_for_mode[maybe_mode] = value
      end
    end
    if type(maybe_mode) == "table" then
      for _, mode in ipairs(maybe_mode) do
        if vim.tbl_contains(VALID_MODES_FOR_ACTIONS, mode) then
          spec_for_mode[mode] = value
        end
      end
    end
  end
  if vim.tbl_isempty(spec_for_mode) then
    error("Action has no mode available")
  end

  local action_obj = {
    meta = { action_version = "v2" },
    mode_actions = vim.tbl_map(mk_action_single_mode, spec_for_mode),
  }
  if global_spec.debug then
    print("Debugging action v2:", vim.inspect(action_obj))
  end
  return setmetatable(action_obj, ActionSpec_mt)
end
function mk_configurable_action(spec)
  -- NOTE: A configurable action has options (inspired from NixOS options, at a single level),
  -- and can be configured where it's going to be used.

  -- TODO: validate `spec` inputs!
  assert(spec.options, "a configurable action must actually expose options to be configurable..")
end
function mk_action_opt(spec)
  -- NOT IMPLEMENTED YET
  return false
end


----------------------------

-- ------ PLUGINS
local plugin_specs = require"mycfg.plugs"
require"mylib.do_simple_plugin_boot" {
  all_plugin_specs = plugin_specs,
  install_dir = vim.fn.stdpath"state" .. "/managed-plugins/start",
}

-- This is my config here!
-- FIXME: I'd like to have a better place to put these,
-- maybe even under a kind of 'plugin' in my declared_plugins tree!
-- (see ~/.dot/nvim-myplugins/ & PlugSource.myplug ?)

require"mycfg.mappings"


-- FIXME: I don't know where to put this...
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.highlight.on_yank{ timeout = 300 }
  end,
})
