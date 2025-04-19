local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
-- local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = {t.lib_only},
}

--------------------------------

Plug.lib_plenary {
  source = gh"nvim-lua/plenary.nvim",
  desc = "Lua contrib stdlib for plugins, used by many plugins",
  defer_load = { autodetect = true },
}
