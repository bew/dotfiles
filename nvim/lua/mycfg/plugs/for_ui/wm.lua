local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui, t.wm },
}

--------------------------------

Plug {
  source = myplug"tab-zoom-win.nvim",
  desc = "Toggle zoom in tab page",
  tags = {t.wm},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    my_actions.tab_toggle_win_zoom = mk_action_v2 {
      default_desc = "Tab: Toggle window zoom",
      n = require"tab-zoom-win".toggle_zoom
    }

    toplevel_map{mode="n", key="+", action=my_actions.tab_toggle_win_zoom}

    -- Default <C-w>o is dangerous for the layout, make it zoom instead
    toplevel_map{mode="n", key=[[<C-w>o]], action=my_actions.tab_toggle_win_zoom}
    -- Still allow the 'dangerous' operation with `<C-w>O` (maj o)
    toplevel_map{mode="n", key=[[<C-w>O]], action=[[<C-w>o]]}
  end,
}

Plug {
  source = gh"shortcuts/no-neck-pain.nvim",
  desc = "Center window, no neck pain!",
  tags = {t.wm},
  on_load = function()
    require"no-neck-pain".setup {
      width = 105, -- default: 100
      minSideBufferWidth = 3,
      integrations = {
        -- FIXME: the Neotree integration is pretty broken when opening Neotree after NoNeckPain..
        Neotree = { position = "right" },
      }
    }

    global_leader_map{mode="n", key="<C-z>", desc="Zen/NoNeckPain", action=vim.cmd.NoNeckPain}
  end,
}
