local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { "ai" }
}

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github

--------------------------------

Plug {
  -- NOTE: This plugin is only necessary to bootstrap and get a permanent Copilot token in a known
  --   local file, which will be accessed by the CodeCompanion plugin later.
  enabled = false,
  source = gh"zbirenbaum/copilot.lua",
  defer_load = { on_cmd = "Copilot" },
  on_load = function()
    -- Run `:Copilot auth` for first use.
    -- 👉 The token will be saved in `~/.config/github-copilot/apps.json`
    require"copilot".setup {
      suggestion = {
        enabled = false,
      },
    }
  end,
}

Plug.codecompanion {
  source = gh"olimorris/codecompanion.nvim",
  desc = "✨ AI-powered coding, seamlessly in Neovim",
  tags = {t.ui, t.editing, t.careful_update},
  depends_on = { Plug.lib_plenary, Plug.ts },
  defer_load = {
    on_event = "VeryLazy",
    -- Necessary to be able to start it from cmdline via `nvim +cmd`
    on_cmd = {"CodeCompanionChat"}
  },
  on_load = function()
    local default_adapter = "copilot"
    require"codecompanion".setup {
      strategies = {
        chat = { adapter = default_adapter },
        inline = { adapter = default_adapter },
        cmd = { adapter = default_adapter }
      }
    }

    -- NOTE: `ca` mode is a special mode to create Commandline Abbreviations
    -- SEE: `:h nvim_set_keymap()`
    -- > Use "ia", "ca" for abbreviation in Insert, Cmdline mode (respectively)
    -- TODO: make a toplevel_abbr("c", ...) helper function or similar
    vim.keymap.set("ca", "cc", "CodeCompanion")
    vim.keymap.set("ca", "ccx", "CodeCompanion explain:")
    vim.keymap.set("ca", "ccc", "CodeCompanionChat")
    vim.keymap.set("ca", "ccb", "CodeCompanionChat #buffer")
  end,
  on_colorscheme_change = function()
    vim.api.nvim_set_hl(0, "CodeCompanionChatTokens", {
      ctermfg = 174,
      italic = true,
    })
  end
}
