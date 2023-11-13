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

    -- vim.keymap.set requires the action to be a string or a function,
    -- so get the underlying keymap action from the ActionSpec.
    keymap_action = spec.action:to_keymap_action()
    if not description and spec.action.default_desc then
      description = spec.action.default_desc
    end
    -- NOTE: raise error when opts conflicts
    keymap_opts = vim.tbl_extend("error", keymap_opts, spec.action.keymap_opts)

    if not debug_keymap then debug_keymap = spec.action.debug end
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

---@class ActionSpecInput
---@field for_mode string|string[] Compatible modes at the start of the action
---@field fn (fun(): any)? The function to execute (conflicts with raw_action)
---@field raw_action any? The raw action to execute (conflicts with fn)
---@field keymap_opts {string: any}? The raw action to execute (conflicts with fn)
---@field debug boolean Wheather to debug the effective keymap args on use

---@class ActionSpec: ActionSpecInput
local ActionSpec_mt = {
  __index = setmetatable(
    {
      to_keymap_action = function(self)
        return self.raw_action
      end,
      supports_mode = function(self, given_modes)
        for _, mode in ipairs(_normalize_mode_or_modes(given_modes)) do
          if not vim.tbl_contains(self.supported_modes, mode) then
            return false
          end
        end
        return true
      end,
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
      -- local replace_keycodes = self.keymap_opts.expr or false
      -- local feedkeys_mode = ""
      -- if self.keymap_opts.remap or not self.keymap_opts.noremap then
      --   feedkeys_mode = feedkeys_mode .. "m" -- remap
      -- else
      --   feedkeys_mode = feedkeys_mode .. "n" -- noremap
      -- end
      -- feedkeys_mode = feedkeys_mode .. "x" -- execute right away
      -- feedkeys_mode = feedkeys_mode .. "!" -- do not auto-end insert mode
      -- -- if self.debug then
      --   print("Debugging ad-hoc feedkeys:",
      --     "raw_action:", vim.inspect(self.raw_action),
      --     "feedkeys_mode:", vim.inspect(feedkeys_mode),
      --     "replace_keycodes:", replace_keycodes
      --   )
      -- -- end
      -- -- NOTE: assumes termcodes haven't been replaced yet (<C-x>, <Plug>, etc..)
      -- vim.api.nvim_feedkeys(self.raw_action, feedkeys_mode, replace_keycodes)
    else
      error(_f("Cannot ad-hoc exec raw action of type", raw_action_type))
    end
  end
}

function _normalize_mode_or_modes(modes)
  return type(modes) == "table" and modes or { modes }
end

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
  return setmetatable({
    default_desc = spec.default_desc or false,
    supported_modes = _normalize_mode_or_modes(spec.for_mode),
    raw_action = raw_action,
    keymap_opts = spec.keymap_opts or {},
    debug = spec.debug or false,
  }, ActionSpec_mt)
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
  callback = function() vim.highlight.on_yank{ timeout = 300 } end,
})
