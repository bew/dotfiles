-- FIXME: &rtp and &pp defaults to loaaads of stuff on NixOS, using the
-- maannyyyy dirs from XDG_CONFIG_DIRS & XDG_DATA_DIRS...
-- => Remove the ones from these folders that don't actually exist?
--
-- Force rtp to use the new ~/.dot/nvim-wip dir, not the std ~/.config/nvim one (with my old config)
-- NOTE: Here is how lazy.nvim resets these:
-- https://github.com/folke/lazy.nvim/blob/c7122d64cdf16766433588486adcee67571de6d0/lua/lazy/core/config.lua#L183

print("Starting config load", vim.fn.strftime"%c")

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

-- NOTE: Read more about neovim's custom lua file loader at:
-- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/_init_packages.lua

-- Load options early in case the initialization of some plugin requires them.
-- (e.g: for filetype on)
vim.cmd[[
runtime! options.vim

colorscheme bew256-dark
]]

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

-- Mapping helpers, to be moved, probably

-- Create initial leader maps (to be used in init of some plugins)
wk_leader_n_maps = {}
wk_leader_v_maps = {}

--- Get the which_key's leader map for the given mode
function get_wk_leader_maps_for_mode(mode)
  local wk_leader_maps_for_mode = {
    n = wk_leader_n_maps,
    v = wk_leader_v_maps,
  }
  return wk_leader_maps_for_mode[mode]
end

--- Define leader map group for which_key plugin
function leader_map_define_group(spec)
  assert(spec.mode, "mode is required")
  for _, m in ipairs(spec.mode) do
    wk_leader_maps = get_wk_leader_maps_for_mode(m)
    if wk_leader_maps then
      wk_leader_maps[spec.prefix_key] = { name = spec.name }
    end
  end
end

--- Create top level map
function toplevel_map(spec)
  assert(spec.mode, "mode is required")
  assert(spec.key, "key is required")
  assert(spec.action, "action is required")
  vim.keymap.set(spec.mode, spec.key, spec.action, spec.opts)
end

--- Create leader map & register it on which_key plugin
function leader_map(spec)
  toplevel_map(vim.tbl_extend("force", spec, { key = "<leader>"..spec.key }))
  -- when desc is set, put the key&desc in appropriate whichkey maps
  if spec.desc then
    for _, m in ipairs(spec.mode) do
      wk_leader_maps = get_wk_leader_maps_for_mode(m)
      if wk_leader_maps then
        wk_leader_maps[spec.key] = spec.desc
      end
    end
  end
end

--- Helper to create remap-enabled leader map, see `leader_map` for details
function leader_remap(spec)
  if not spec.opts then
    spec.opts = {}
  end
  spec.opts.remap = true
  leader_map(spec)
end

----------------------------

-- ------ PLUGINS
local declared_plugins = require"mycfg.declare_plugins"
require"mylib.do_simple_plugin_boot"(declared_plugins.all_plugin_specs)

--require"mycfg.mappings"


-- " FIXME: I don't know where to put this...
-- au TextYankPost * silent! lua vim.highlight.on_yank({ timeout = 300 })

-- " When editing a file, always jump to the last known cursor position.
-- " Don't do it when the position is invalid or when inside an event handler
-- " (happens when dropping a file on gvim).
-- " Also don't do it when the mark is in the first line, that is the default
-- " position when opening a file.
-- " FIXME: still needed with nvim?
-- autocmd BufReadPost *
--     \ if line("'\"") > 1 && line("'\"") <= line("$") |
--     \ exe "normal! g`\"" |
--     \ endif
