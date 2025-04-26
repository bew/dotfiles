local PluginSystem = require"mylib.plugin_system"

-- Define custom plugin source for my local plugins
---@param name string Name of my local plugin (found in $NVIM_BEW_MYPLUGINS_PATH)
---@return plugsys.PlugSourceLocal
PluginSystem.sources.myplug = function(name)
  local myplugins_path = vim.env.NVIM_BEW_MYPLUGINS_PATH
  assert((
    myplugins_path or vim.fn.filereadable(myplugins_path) == 1
  ), "$NVIM_BEW_MYPLUGINS_PATH is not set or doesn't exist!!")
  return PluginSystem.sources.local_path {
    name = name,
    path = vim.fs.normalize(myplugins_path .. "/" .. name)
  }
end

---@diagnostic disable: missing-fields
-- Having different type for table & `__newindex` isn't supported nor easy to.. skip diags for this..
--   REF: https://github.com/LuaLS/lua-language-server/issues/3020
PluginSystem.tags.careful_update = { desc = "Plugins I want to update carefully" }
PluginSystem.tags.vimscript = { desc = "Plugins in vimscript" }
PluginSystem.tags.ui = { desc = "Plugins for the global UI" }
PluginSystem.tags.wm = { desc = "Plugins around Window Management" }
PluginSystem.tags.content_ui = { desc = "Plugins for content UI" }
PluginSystem.tags.editing = { desc = "Plugins about code/content editing" }
PluginSystem.tags.insert = { desc = "Plugins adding stuff in insert mode" }
PluginSystem.tags.ts = { desc = "Plugins made to use Treesitter information" }
PluginSystem.tags.git = { desc = "Plugins around git VCS" }
PluginSystem.tags.textobj = { desc = "Plugins to add textobjects" }
PluginSystem.tags.ft_support = { desc = "Plugins to support specific filetype(s)" }
PluginSystem.tags.lib_only = { desc = "Plugins that are only useful to other plugins" }
PluginSystem.tags.need_better_plugin = { desc = "Plugins that are 'meh', need to find a better one" }
---@diagnostic enable: missing-fields

--------------------------------

require"mycfg.plugs.for_ai_llm"
require"mycfg.plugs.for_config"
require"mycfg.plugs.for_file_editing"
require"mycfg.plugs.for_ft"
require"mycfg.plugs.for_git"
require"mycfg.plugs.for_treesitter"
require"mycfg.plugs.for_ui"
require"mycfg.plugs.general_libs"
require"mycfg.plugs.pkg_manager"
-- PluginSystem.show_plugins_dependencies() -- DEBUG

PluginSystem.check_missing_plugins()
local all_plugs = PluginSystem.all_plugin_specs()

return {
  ---@param opts plugsys.BootPlugOpts
  boot_plugins = function(opts)
    require"mylib.do_simple_plugin_boot"(all_plugs, opts)
  end,
}
