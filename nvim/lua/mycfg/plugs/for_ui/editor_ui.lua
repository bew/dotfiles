local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui, t.content_ui },
}

--------------------------------

Plug {
  source = myplug"restore-cursor.nvim",
  desc = "Restore cursor when opening file for first time, customizable :)",
  tags = {},
  on_load = function()
    require("restore-cursor").setup()
  end,
}


Plug {
  source = gh"0xAdk/full_visual_line.nvim",
  desc = "Highlights whole lines in linewise visual mode",
  tags = {},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"full_visual_line".setup()

    my_actions.full_visual_line = {}
    my_actions.full_visual_line.toggle = mk_action_v2 {
      default_desc = "Full Visual Line - Toggle",
      [{"n", "v"}] = function()
        require"full_visual_line".toggle()
      end,
    }
  end,
}

Plug {
  source = gh"mcauley-penney/visual-whitespace.nvim",
  desc = "Reveal whitespace characters in visual mode, like VSCode",
  tags = {},
  version = { branch = "compat-v10" }, -- for nvim 0.10 support
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"visual-whitespace".setup {
      highlight = {
        ---@diagnostic disable-next-line: undefined-field (fixed in v0.11.0)
        ctermfg = vim.api.nvim_get_hl(0, {name="Comment"}).ctermfg,
        ---@diagnostic disable-next-line: undefined-field (fixed in v0.11.0)
        ctermbg = vim.api.nvim_get_hl(0, {name="VisualNormal"}).ctermbg,
      },
      space_char = " ", -- avoid noise
      nl_char = "󰘌 ",
      cr_char = "󰞗 ",
      tab_char = "󱦰 ",
    }
  end,
}

Plug {
  source = gh"lukas-reineke/indent-blankline.nvim",
  desc = "Indent guides",
  tags = {t.content_ui},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require("ibl").setup {
      indent = {
        char = {"¦", "│"},
      },
      scope = {
        char = {"▎"}, -- line smashed to the left, for nicer rendering
        show_exact_scope = true, -- Don't mark whole lines at start/end of the scope
        -- include = {
        --   -- Additional TS node types that are considered as a scope (by language)
        --   -- note: it's a bit too much, and I loose the _real_ scope, would be nice to have two
        --   --   scoping lines: the current (real) scope + table/dict/object scope 🤔
        --   node_type = {
        --     lua = {"table_constructor"},
        --     nix = {"attrset_expression"},
        --   }
        -- }
      },
    }
    -- NOTE: Once scope is setup, see doc for hooks.builtin.scope_highlight_from_extmark to use
    -- the same highlight groups as rainbow-highlights.
    local hooks = require"ibl.hooks"
    -- Replaces the first indentation guide for space/tab indentation with a normal space
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)
  end,
  on_colorscheme_change = function()
    vim.api.nvim_set_hl(0, "IblIndent", { ctermfg = 237 })
    -- note: `fg` necessary because it is used for the underline color of first/last line of scope
    vim.api.nvim_set_hl(0, "IblScope",  { ctermfg = 239, fg = "#4f5258" })
  end,
}

Plug {
  source = gh"echasnovski/mini.hipatterns",
  desc = "Highlight patterns in text",
  tags = {t.content_ui},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"mini.hipatterns".setup {
      highlighters = require"mycfg.hl_patterns"
    }
  end,
}
