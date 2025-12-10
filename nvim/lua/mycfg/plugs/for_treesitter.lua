local PluginSystem = require"mylib.plugin_system"
local dist_managed_opt_plug = PluginSystem.sources.dist_managed_opt_plug
local fallback = PluginSystem.sources.fallback

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github

local Plug = PluginSystem.get_plugin_declarator {
  default_tags = {t.ts},
}

local A = require"mylib.action_system"
local K = require"mylib.keymap_system"
local U = require"mylib.utils"

--------------------------------

Plug.ts {
  source = fallback("treesitter", dist_managed_opt_plug"nvim-treesitter"),
  desc = "Nvim Treesitter configurations and abstraction layer",
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    ---@diagnostic disable-next-line: missing-fields (don't care, it works)
    require"nvim-treesitter.configs".setup {
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
  tags = {t.editing},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local lang_utils = require"treesj.langs.utils"
    local langs = require"treesj.langs".presets
    -- Override some language settings
    -- ref: https://github.com/Wansmer/treesj/blob/main/README.md#basic-node
    -- ref: https://github.com/Wansmer/treesj/blob/main/lua/treesj/langs/default_preset.lua
    do
      -- ref: https://github.com/Wansmer/treesj/blob/main/lua/treesj/langs/python.lua
      langs.python.argument_list = lang_utils.set_preset_for_args({
        split = { last_separator = true },
      })
    end

    -- TODO: impl treesj for Terraform's list/dict generator literals
    --   e.g. [for foo in bar: value] or {for foo in bar: key => value}

    -- TODO: change treesj for Nix's destructuring function argument
    --   e.g. `{foo, bar ? 42}: bar` which currently gives ugly formatting on 'split' action..

    local tsj = require"treesj"
    tsj.setup {
      use_default_keymaps = false,
      -- 'join' action doesn't execute if resulting line is longer than `max_join_length`.
      -- It defaults to 120, but it's more annoying than anything else.. just disable it!
      max_join_length = 999,
      langs = langs,
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

Plug {
  source = gh"nvim-treesitter/nvim-treesitter-context",
  desc = "Show code context",
  tags = {"ui"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local tsctx = require"treesitter-context"
    tsctx.setup {
      multiwindow = true, -- When false, only enabled on current bufwin, everywhere when true.
      max_lines = "35%", -- How many lines the window should span. Values <= 0 mean no limit.
      multiline_threshold = 5, -- Maximum number of lines to show for a SINGLE context item
      mode = "topline", -- Line used to calculate context. (Either "cursor" or "topline")
      trim_scope = "inner", -- When scope is too big for win height, trim 'inner' context lines
      -- Separator between context and content (must be single char).
      -- (it's actually annoying as it's hiding a whole line below the context win)
      -- separator = "🮃"
    }

    my_actions.ts_context_toggle = A.mk_action {
      default_desc = "Toggle context",
      n = tsctx.toggle,
    }
    my_actions.ts_context_jump_to = A.mk_action {
      default_desc = "Jump to (count) context",
      n = function()
        local tsctx = require"treesitter-context"
        if not tsctx.enabled() then
          error("treesitter-context is not enabled for this buffer")
        end
        tsctx.go_to_context(vim.v.count1)
      end,
    }
    K.local_leader_map_define_group{mode={"n"}, prefix_key="cx", name="+context"}
    K.local_leader_map{mode="n", key=[[cx<Space>]], action=my_actions.ts_context_toggle}
    K.local_leader_map{mode="n", key=[[cxx]], action=my_actions.ts_context_jump_to}
  end,
  on_colorscheme_change = function()
    local hl_ctx = U.hl.set("TreesitterContext", {
      ctermfg = 248,
      ctermbg = 235,
    })
    U.hl.set("TreesitterContextSeparator", {
      ctermfg = hl_ctx.ctermbg, -- (border uses FG, should match context' BG)
      ctermbg = hl_ctx.ctermbg -2, -- darker
    })
  end,
}
