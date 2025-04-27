local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.get_plugin_declarator()
local dist_managed_opt_plug = PluginSystem.sources.dist_managed_opt_plug
local fallback = PluginSystem.sources.fallback

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github

local A = require"mylib.action_system"
local K = require"mylib.keymap_system"

--------------------------------

Plug.ts {
  source = fallback("treesitter", dist_managed_opt_plug"nvim-treesitter"),
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

      -- Module for matchup (https://github.com/andymass/vim-matchup)
      matchup = { enable = true },
    }
  end,
}

Plug {
  source = gh"Wansmer/treesj",
  desc = "Neovim plugin for splitting/joining blocks of code",
  tags = {t.ts, t.editing},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local tsj = require"treesj"
    tsj.setup {
      use_default_keymaps = false,
    }

    my_actions.treesj_toggle = A.mk_action {
      default_desc = "[Treesj] Toggle TS block split/join",
      n = tsj.toggle,
    }
    my_actions.treesj_split = A.mk_action {
      default_desc = "[Treesj] Split TS block",
      n = tsj.split,
    }
    my_actions.treesj_join = A.mk_action {
      default_desc = "[Treesj] Join TS block",
      n = tsj.join,
    }
    K.local_leader_map_define_group{mode={"n"}, prefix_key="j", name="+split/join"}
    K.local_leader_map{mode={"n"}, key="j<Space>", action=my_actions.treesj_toggle}
    K.local_leader_map{mode={"n"}, key="js", action=my_actions.treesj_split}
    K.local_leader_map{mode={"n"}, key="jj", action=my_actions.treesj_join}
  end
}
