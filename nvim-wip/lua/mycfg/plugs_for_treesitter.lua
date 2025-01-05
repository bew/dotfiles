local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.PlugDeclarator

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github

--------------------------------

Plug.ts {
  source = PluginSystem.sources.dist_managed_opt_plug"nvim-treesitter",
  desc = "Nvim Treesitter configurations and abstraction layer",
  tags = {t.ts},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    ---@diagnostic disable-next-line: missing-fields (don't care, it works)
    require'nvim-treesitter.configs'.setup {
      auto_install = false,

      -- Enable TS modules
      highlight = { enable = true },
      indent = { enable = true },
    }
  end,
}
