-- FIXME: &rtp and &pp defaults to loaaads of stuff on NixOS, using the
-- maannyyyy dirs from XDG_CONFIG_DIRS & XDG_DATA_DIRS...
-- => Remove the ones from these folders that don't actually exist?
--
-- Force rtp to use the new ~/.dot/nvim-wip dir, not the std ~/.config/nvim one (with my old config)
-- NOTE: Here is how lazy.nvim resets these:
-- https://github.com/folke/lazy.nvim/blob/c7122d64cdf16766433588486adcee67571de6d0/lua/lazy/core/config.lua#L183

-- TODO: re-enable, and contribute fixes to all plugins with undefined global vars..
--_G = setmetatable(_G, {
--  __index = function(_, key)
--    error("Unknown global variable '" .. key .. "'")
--  end,
--})

-- Setup this nvim instance to work with a completely different nvim folder,
-- because I want to have multiple configs, potentially available at the same time.
--
-- See this issue for future better way to solve this:
-- https://github.com/neovim/neovim/issues/21691
local nvim_cfg_path = "/home/bew/.dot/nvim-wip"
-- Override stdpaths
--
-- FIXME: I can't simply require"custom_stdpaths", because I would need
-- runtimepath set to my custom config path beforehand...
local custom_stdpaths = dofile(nvim_cfg_path .. "/lua/mylib/custom_stdpaths.lua")
custom_stdpaths.setup {
  overrides = {
    {
      config = nvim_cfg_path,
      data = "/home/bew/.local/share/nvim-wip",
      state = "/home/bew/.local/state/nvim-wip",
    },
    --require"mylib.custom_stdpaths".NVIM_STDPATH_env_overrides,
  }
}
assert(vim.fn.stdpath"config" == nvim_cfg_path, "stdpath override FAILED ?!")

vim.opt.runtimepath = {
  vim.fn.stdpath"config",
  -- (system) "/etc/xdg/nvim",
  --vim.fn.stdpath"data" .. "/site",
  "/home/bew/.nix-profile/share/nvim/site",
  -- (system) "/usr/share/nvim/site",
  -- (system) "/usr/local/share/nvim/site",

  vim.env.VIMRUNTIME,

  "/home/bew/.nix-profile/share/nvim/site/after",
  --vim.fn.stdpath"data" .. "/site/after",
  -- (system) "/etc/xdg/nvim/after",
  vim.fn.stdpath"config" .. "/after",
}
vim.opt.packpath = {
  vim.fn.stdpath"config",
  vim.env.VIMRUNTIME,
}

-- Setup known-paths for my own config:
MY_KNOWN_PATHS = setmetatable({
   myplugins = "/home/bew/.dot/nvim-myplugins",
}, require"mylib.mt_utils".KeyRefMustExist_mt)

-- NOTE: Read more about neovim's custom lua file loader at:
-- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/_init_packages.lua

-- Load options early in case the initialization of some plugin requires them.
-- (e.g: for filetype on)
require"mycfg.options"

-- NOTE: If trying to move it AFTER plugin load, double check git signs are of correct color!
vim.cmd[[ colorscheme bew256-dark ]]

-- Specify the python binary to use for the plugins, this is necessary to be
-- able to use them while inside a project' venv (which does not have pynvim)
-- let $NVIM_DATA_HOME = ($XDG_DATA_HOME != '' ? $XDG_DATA_HOME : $HOME . "/.local/share") . "/nvim-wip"
-- NOTE: ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ use custom dir for nvim-wip !!!!!!!!

-- FIXME: python env, still needed?
-- let $NVIM_PY_VENV = $NVIM_DATA_HOME . "/py-venv"
-- let g:python3_host_prog = $NVIM_PY_VENV . "/bin/python3"
-- NOTE: Make sure to install pynvim in this environment! (and jedi for py dev)

-- map leader definition - space
vim.g.mapleader = " "
-- IDEA: Change <leader> to <Ctrl-space> | Have <localleader> be <space>
-- And the CtrlSpace plugin would be <leader><space> or <leader><leader>
-- Also give a new leader possibility with <Alt-space> (:

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

--- Define leader map group for which_key plugin
function _map_define_group(spec)
  assert(spec.mode, "mode is required")
  for _, m in ipairs(spec.mode) do
    local wk_maps = get_wk_maps_for_mode(m)
    if wk_maps then
      wk_maps[spec.prefix_key] = { name = spec.name }
    end
  end
end

function toplevel_map_define_group(spec)
  _map_define_group(spec)
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
    -- vim.keymap.set requires the action to be a string or a function,
    -- so get the underlying keymap action from the ActionSpec.
    keymap_action = spec.action:to_keymap_action()
    if not description then
      description = spec.action.default_desc
    end
    -- NOTE: raise error when opts conflicts
    keymap_opts = vim.tbl_extend("error", keymap_opts, spec.action.keymap_opts)

    if not debug_keymap then debug_keymap = spec.action.debug end
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

  -- when the description is set, put the key&desc in appropriate whichkey maps
  if description then
    local mode_tbl
    if type(spec.mode) == "table" then
      mode_tbl = spec.mode
    else
      mode_tbl = {spec.mode}
    end
    for _, m in ipairs(mode_tbl) do
      local wk_maps = get_wk_maps_for_mode(m)
      if wk_maps then
        wk_maps[spec.key] = description
      end
    end
  end
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
      end
    },
    -- FIXME: is there a better/simpler way to chain __index metamethods?
    require"mylib.mt_utils".KeyRefMustExist_mt
  ),
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
    raw_action = function() spec.fn() end
  elseif spec.raw_action then
    raw_action = spec.raw_action
  else
    error("spec.fn or spec.raw_action must be set!")
  end
  return setmetatable({
    default_desc = spec.default_desc,
    for_mode = spec.for_mode, -- NOTE: currently ZERO checks are done with this..
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
