local U = require"mylib.utils"
local _f = U.str_space_concat
local _s = U.str_surround
local _q = U.str_simple_quote_surround

local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.MasterDeclarator:get_anonymous_plugin_declarator()
local NamedPlug = PluginSystem.MasterDeclarator:get_named_plugin_declarator()

-- Define custom plugin source for my local plugins
PluginSystem.sources.myplug = function(name)
  return PluginSystem.sources.local_path {
    name = name,
    path = vim.fs.normalize(MY_KNOWN_PATHS.myplugins .. "/" .. name)
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
predefined_tags.extensible = { desc = "Plugins that can be extended" } -- TODO: apply on all relavant!
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
NamedPlug.pkg_manager {
  source = gh"folke/lazy.nvim",
  desc = "A modern plugin manager for Neovim",
  tags = {"boot", t.careful_update},
  on_boot = function(ctx)
    if not U.is_module_available("lazy") then return false end
    local function enabled_plugins_filter(plug)
      if plug.on_boot then return false end -- not a regular plugin
      return plug.enable ~= false
    end

    local lazy_plugin_specs = {}
    for _, plug in pairs(U.filter_list(ctx.all_plugin_specs, enabled_plugins_filter)) do
      local lazy_single_spec = {}
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
      table.insert(lazy_plugin_specs, lazy_single_spec)
    end
    local plug_names = {}
    for _, plug in pairs(lazy_plugin_specs) do
      table.insert(plug_names, plug[1])
    end
    --print("Loading lazy plugins:", vim.inspect(plug_names))
    require("lazy").setup(lazy_plugin_specs, {
      root = "/home/bew/.dot/nvim-wip/pack/lazy-managed-plugins/start",
      install = { missing = false },
      custom_keys = false,
      change_detection = { enabled = false }, -- MAYBE: try it?
      cache = { enabled = false },
      performance = { reset_packpath = false },
      git = {
        -- In the Logs UI, show commits that are 'pending'
        -- (for plugins not yet updated to their latest fetched commit)
        -- => Will show nothing for plugins that are up-to-date, but I can always go
        --    where the plugin is (can copy path from plugin details) and `git log`!
        log = {"..origin/HEAD"}
      },
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