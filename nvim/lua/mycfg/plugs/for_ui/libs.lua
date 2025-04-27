local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
-- local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui, t.lib_only },
}

--------------------------------

Plug.lib_web_devicons {
  source = gh"kyazdani42/nvim-web-devicons",
  desc = "Find (colored) icons for file type",
  defer_load = { autodetect = true },
  on_load = function()
    require"nvim-web-devicons".set_default_icon("", "#cccccc", 244)
    require"nvim-web-devicons".setup { default = true } -- give a default icon when nothing matches
  end,
}

Plug.lib_nui {
  source = gh"MunifTanjim/nui.nvim",
  desc = "UI Component Library for Neovim",
  defer_load = { autodetect = true },
}
