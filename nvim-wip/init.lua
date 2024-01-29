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

-- map leader definition - space
vim.g.mapleader = " "
-- IDEA: Change <leader> to <C-space> | Have <localleader> be <space>
-- And the CtrlSpace plugin would be <leader><Space> or <leader><leader>
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
  for _, m in ipairs(spec.mode) do
    local wk_maps = get_wk_maps_for_mode(m)
    if wk_maps then
      wk_maps[spec.prefix_key] = { name = spec.name }
    end
  end
end

function leader_map_define_group(spec)
  spec.prefix_key = "<leader>"..spec.prefix_key
  toplevel_map_define_group(spec)
end

--- Create top level map
function toplevel_map(spec)
  vim.validate{
    mode={spec.mode, {"string", "table"}},
    key={spec.key, "string"},
    action={
      spec.action,
      function(a)
        if vim.tbl_contains({"function", "string"}, type(a)) then
          return true
        end
        return type(a) == "table" and a.to_keymap_action ~= nil
      end,
    },
    opts={spec.opts, "table", true}, -- optional
    debug={spec.debug, "boolean", true}, -- optional
  }
  local debug_keymap = spec.debug or false
  local keymap_action = spec.action
  local keymap_opts = spec.opts or {}
  local description = spec.desc
  if type(spec.action) == "table" then
    if not spec.action:supports_mode(spec.mode) then
      error(_f("Action does not support all given modes:", vim.inspect(spec.mode)))
    end

    -- FIXME: Complex actions (like `my_actions.hlsearch_current`) can have different desc/function
    --   for each mode.
    --   => Need to generate a set of keymap parameters for each in this case..
    --   (only the case when `spec.for_mode` is a table? (idea: make it always a table?))

    -- vim.keymap.set requires the action to be a string or a function,
    -- so get the underlying keymap action from the ActionSpec.
    keymap_action = spec.action:to_keymap_action()
    if not description and spec.action.default_desc then
      description = spec.action.default_desc
    end
    -- NOTE: raise error when opts conflicts
    keymap_opts = vim.tbl_extend("error", keymap_opts, spec.action.keymap_opts)

    debug_keymap = debug_keymap or spec.action.debug
  end
  if description then
    keymap_opts.desc = description
  end
  if debug_keymap then
    print("Debugging keymap:",
      "mode:", vim.inspect(spec.mode),
      "key:", vim.inspect(spec.key),
      "raw_action:", vim.inspect(keymap_action),
      "opts:", vim.inspect(keymap_opts)
    )
  end
  vim.keymap.set(spec.mode, spec.key, keymap_action, keymap_opts)
end

--- Create leader map & register it on which_key plugin
function leader_map(spec)
  toplevel_map(vim.tbl_extend("force", spec, {
    key = "<leader>"..spec.key,
  }))
end

--- Helper to create remap-enabled leader map, see `leader_map` for details
function leader_remap(spec)
  if not spec.opts then
    spec.opts = {}
  end
  spec.opts.remap = true
  leader_map(spec)
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

---@class ActionSpecInput
---@field for_mode string|string[] Compatible modes at the start of the action
---@field fn? (fun(): any) The function to execute (conflicts with raw_action)
---@field raw_action? any The raw action to execute (conflicts with fn)
---@field keymap_opts? {string: any} The raw action to execute (conflicts with fn)
---@field debug? boolean Wheather to debug the effective keymap args on use

---@class ActionSpec: ActionSpecInput
local ActionSpec_mt = {
  __index = setmetatable(
    {
      to_keymap_action = function(self)
        return self.raw_action
      end,
      supports_mode = function(self, given_modes)
        for _, mode in ipairs(U.normalize_arg_one_or_more(given_modes)) do
          if not vim.tbl_contains(self.supported_modes, mode) then
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
  __call = function(self)
    if self.keymap_opts.expr then
      error("Ad-hoc exec of expr action is NOT tested/supported")
    end
    local raw_action_type = type(self.raw_action)
    if raw_action_type == "function" then
      self.raw_action()
    elseif raw_action_type == "string" then
      error("Ad-hoc exec of string raw action is not implemented (failed..)")
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
      error(_f("Cannot ad-hoc exec raw action of type", raw_action_type))
    end
  end
}

---@type {[string]: ActionSpec}
my_actions = {}
---@param spec ActionSpecInput
---@return ActionSpec
function mk_action(spec)
  vim.validate{
    spec={spec, "table"},
    spec_fn={spec.fn, "function", true}, -- optional
    spec_action={spec.raw_action, "string", true}, -- optional (only when fn not set)
    spec_for_mode={spec.for_mode, {"string", "table"}},
    spec_desc={spec.default_desc, "string", true}, -- optional
    spec_keymap_opts={spec.keymap_opts, "table", true}, -- optional
    spec_debug={spec.debug, "boolean", true}, -- optional
  }
  if spec.opts then error("Set keymap options using field `keymap_opts`") end
  local raw_action
  if spec.fn then
    raw_action = spec.fn
  elseif spec.raw_action then
    raw_action = spec.raw_action
  else
    error("spec.fn or spec.raw_action must be set!")
  end
  -- TODO: normalize actual actions to `raw_action_for_mode` table
  return setmetatable({
    default_desc = spec.default_desc or false,
    supported_modes = U.normalize_arg_one_or_more(spec.for_mode),
    raw_action = raw_action,
    keymap_opts = spec.keymap_opts or {},
    debug = spec.debug or false,
  }, ActionSpec_mt)
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
