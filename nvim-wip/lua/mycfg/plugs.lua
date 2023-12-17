local U = require"mylib.utils"
local _f = U.str_space_concat
local _s = U.str_surround
local _q = U.str_simple_quote_surround

local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.MasterDeclarator:get_anonymous_plugin_declarator()
local NamedPlug = PluginSystem.MasterDeclarator:get_named_plugin_declarator()

-- Define custom plugin source for my local plugins
local myplugins_path = vim.env.NVIM_BEW_MYPLUGINS_PATH
assert((
  myplugins_path or not vim.fn.filereadable(myplugins_path)
), "$NVIM_BEW_MYPLUGINS_PATH is not set or doesn't exist!!")
PluginSystem.sources.myplug = function(name)
  return PluginSystem.sources.local_path {
    name = name,
    path = vim.fs.normalize(myplugins_path .. "/" .. name)
  }
end

local predefined_tags = PluginSystem.predefined_tags
predefined_tags.careful_update = { desc = "Plugins I want to update carefully" }
predefined_tags.vimscript = { desc = "Plugins in vimscript" }
predefined_tags.ui = { desc = "Plugins for the global UI" }
predefined_tags.code_ui = { desc = "Plugins for code UI" }
predefined_tags.editing = { desc = "Plugins about code/content editing" }
predefined_tags.insert = { desc = "Plugins adding stuff in insert mode" }
predefined_tags.git = { desc = "Plugins around git VCS" }
predefined_tags.textobj = { desc = "Plugins to add textobjects" }
predefined_tags.ft_support = { desc = "Plugins to support specific filetype(s)" }
predefined_tags.lib_only = { desc = "Plugins that are only useful to other plugins" }
predefined_tags.extensible = { desc = "Plugins that can be extended" } -- TODO: apply on all relevant!
predefined_tags.need_better_plugin = { desc = "Plugins that are 'meh', need to find a better one" }

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = predefined_tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug

--------------------------------

Plug {
  source = myplug"debug-autocmds.nvim",
  desc = "Tool to debug/understand autocmd flow while using neovim",
  tags = {"utils", "debug"},
  on_load = function()
    require("debug-autocmds").setup{
      global_tracking_on_start = false, -- switch to `true` to debug builtin events from start :)
    }
  end,
}

Plug {
  source = myplug"smart-bol.nvim",
  desc = "Provide action to cycle movements ^ and 0 with a single key",
  tags = {"movement", t.insert},
  on_load = function()
    -- I: Move cursor to begin/end of line
    -- NOTE: BREAKS UNDO
    --   I couldn't make the smart-bol plugin work in insert mode in a 'repeat'-able way nor without
    --   breaking undo...
    --   (moving to end could, but having begin/end have different behavior is a no-no)
    --
    -- NOTE: Direct mapping of <M-^> might need special terminal config to work instantly...
    -- otherwise dead key might be triggered (like `^e` to make `ê`).
    -- (wezterm implemented this after my issue: https://github.com/wez/wezterm/issues/877)
    -- vim.cmd[[inoremap <M-^> <C-g>U<Home>]] -- BUT: <Home> moves like 0 not like ^
    local smart_bol_act = require"smart-bol.actions"
    toplevel_map{mode={"n", "i"}, key=[[<M-^>]],  desc="smart bol", action=smart_bol_act.do_smart_bol}
    toplevel_map{mode={"n", "i"}, key=[[<Home>]], desc="smart bol", action=smart_bol_act.do_smart_bol}
    toplevel_map{mode={"n", "i"}, key=[[<M-$>]],  desc="eol", action=[[<End>]]}
  end,
}

NamedPlug.lib_plenary {
 source = gh"nvim-lua/plenary.nvim",
 desc = "Lua contrib stdlib for plugins, used by many plugins",
 tags = {t.lib_only}
}

-- NOTE: I don't want all the lazyness and perf stuff of 'lazy'
-- I want a simple plugin loader (using neovim packages), with nice recap UI,
-- interactive update system, with a lockfile (usable from Nix).
--
-- I want a way to ask what plugins has updates, see git log, and update plugins individually on
-- demand (or by tags inclusion/exclusion).
-- => It's actually already possible (except filtering on tags) with `Lazy check` then `Lazy logs`
--
-- TODO: Ask a way to disable the 'update' tab, which is potentially too dangerous,
-- I want to review plugins updates before I actually update them!
--
-- TODO: Make a dedicated way to register a package manager,
--   so we can enforce a set of fields / structure
NamedPlug.pkg_manager {
  source = gh"folke/lazy.nvim",
  desc = "A modern plugin manager for Neovim",
  tags = {"boot", t.careful_update},
  install_path = vim.fn.stdpath("data") .. "/pkg-manager--lazy",
  bootstrap_fn = function(self, ctx)
    local clone_cmd_parts = {
      "git",
      "clone",
      "--filter=blob:none", -- don't fetch blobs until git needs them
      self.source.url,
      self.install_path,
    }
    local clone_cmd = table.concat(clone_cmd_parts, " ")
    print("Package manager not found! Install with:", clone_cmd)
  end,
  on_boot = function(ctx)
    if not U.is_module_available("lazy") then return false end
    local function enabled_plugins_filter(plug)
      if plug.on_boot then return false end -- not a regular plugin
      return plug.enable ~= false
    end

    local lazy_plugin_specs = {}
    for _, plug in pairs(U.filter_list(ctx.all_plugin_specs, enabled_plugins_filter)) do
      local lazy_single_spec = {
        -- Set the plugin name, so we can easily reference other plugins by name
        -- (e.g. for plugin dependencies)
        name = plug.source.name,
      }
      if plug.source.type == "github" then
        lazy_single_spec[1] = plug.source.owner_repo
      elseif plug.source.type == "local_path" then
        lazy_single_spec.dir = plug.source.path
      else
        error(_f("Unknown declared plugin type", _q(plug.source.type)))
      end
      lazy_single_spec.init = plug.on_pre_load
      lazy_single_spec.config = plug.on_load
      if plug.version and plug.version.branch then
        lazy_single_spec.branch = plug.version.branch
      end
      if plug.depends_on then
        local direct_deps = {}
        for _, dep_plug in ipairs(plug.depends_on) do
          table.insert(direct_deps, dep_plug.source.name)
        end
        -- Important to ensure that deps are put in rtp before the plugin requiring them,
        -- can be necessary for vimscript plugins calling autoload functions from immediately
        -- executed plugin-script.
        lazy_single_spec.dependencies = direct_deps
        -- print("Plugin", _q(plug.source.name), "depends on:", vim.inspect(direct_deps)) -- DEBUG
      end
      table.insert(lazy_plugin_specs, lazy_single_spec)
    end
    local plug_names = {}
    for _, plug in pairs(lazy_plugin_specs) do
      table.insert(plug_names, plug[1])
    end
    -- print("Loading lazy plugins:", vim.inspect(plug_names)) -- DEBUG
    require("lazy").setup(lazy_plugin_specs, {
      root = ctx.install_dir,
      git = {
        -- In the Logs UI, show commits that are 'pending'
        -- (for plugins not yet updated to their latest fetched commit)
        -- => Will show nothing for plugins that are up-to-date, but I can always go
        --    where the plugin is (can copy path from plugin details) and `git log`!
        log = {"..origin/HEAD"}
      },
      -- Disable most automations
      install = { missing = false }, -- do not auto-install plugins
      custom_keys = false,
      change_detection = { enabled = false }, -- MAYBE: try it?
      cache = { enabled = false },
      performance = { reset_packpath = false },
    })
  end,
}

--------------------------------

-- FIXME: avoid global state!
require"mycfg.plugs_for_ui"
require"mycfg.plugs_for_ft"
require"mycfg.plugs_for_file_editing"

PluginSystem.MasterDeclarator:check_missing_plugins()
return PluginSystem.MasterDeclarator:all_specs()
