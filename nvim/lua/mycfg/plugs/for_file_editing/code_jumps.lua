local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.editing },
}

local K = require"mylib.keymap_system"
local U = require"mylib.utils"

--------------------------------

Plug {
  source = gh"jremmen/vim-ripgrep",
  desc = "Use RipGrep in Vim and display results in a quickfix list",
  tags = {t.vimscript},
  defer_load = { on_event = "VeryLazy" },
}

Plug {
  source = gh"bassamsdata/namu.nvim",
  desc = "Sleek fuzzy symbol/… navigator, inspired by Zed",
  tags = {t.ui, "nav", "lsp", "ts"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"namu".setup {
      -- Global config, for all modules (symbols/diagnostics/…)
      global = {
        movement = {
          next = { "<C-n>", "<DOWN>", "<M-j>" },
          previous = { "<C-p>", "<UP>", "<M-k>" },
          delete_word = {"<C-w>"},
          clear_line = {"<C-u>"},
        },
        custom_keymaps = {
          vertical_split = {
            desc = "Open in vertical split",
            keys = { "<M-v>" },
          },
          horizontal_split = {
            desc = "Open in horizontal split",
            keys = { "<M-h>" },
          },
        },
        display = {
          format = "tree_guides",
        },
        window = {
          border = "none", -- other borders look very wrong...
          title_prefix = "§ ",
        },
        kindIcons = {
          File = "󰈙",
          Module = "󰏗",
          Namespace = "󰌗",
          Package = "",
          Class = "",
          Method = "󰊕",
          Property = "󰜢",
          Field = "󰜢",
          Constructor = "",
          Enum = "󰒻",
          Interface = "󰕘",
          Function = "󰊕",
          Variable = "󰀫",
          Constant = "󰏿",
          String = "",
          Number = "󰎠",
          Boolean = "󰨙",
          Array = "󰅪",
          Object = "󰅩",
          Key = "",
          Null = "󰟢",
          EnumMember = "󰒻",
          Struct = "",
          Event = "󰉁",
          Operator = "",
          TypeParameter = "",
        },
        AllowKinds = {
          -- defaults (for all filetypes)
          default = {
            "Function",
            "Method",
            "Class",
            "Module",
            -- "Property",
            -- "Variable",
            -- "Constant",
            "Enum",
            "Interface",
            -- "Field",
            "Struct",
            -- "Array"
          },
        },
      },
    }

    K.local_leader_map_define_group{mode="n", prefix_key="cs", name="+namu nav"}
    K.local_leader_map{mode="n", key="css", desc="Buffer Symbols", action=function()
      vim.cmd.Namu"symbols"
    end}
    K.local_leader_map{mode="n", key="csw", desc="Workspace Symbols", action=function()
      vim.cmd.Namu"workspace"
    end}
    K.local_leader_map{mode="n", key="csB", desc="Opened Buffers Symbols", action=function()
      vim.cmd.Namu"watchtower"
    end}
    K.local_leader_map{mode="n", key="csd", desc="Buffer Diagnostics", action=function()
      vim.cmd.Namu"diagnostics"
    end}
    K.local_leader_map{mode="n", key="csD", desc="Workspace Diagnostics", action=function()
      vim.cmd.Namu("diagnostics", "workspace")
    end}
    K.local_leader_map{mode="n", key="csC", desc="Call hierarchy in/out", action=function()
      vim.cmd.Namu("call", "both")
    end}
  end,
  on_colorscheme_change = function()
    U.hl.set("NamuPreview", { ctermbg = 234 })
  end,
}

Plug {
  source = gh"stevearc/aerial.nvim",
  desc = "TS/LSP-based code outline window",
  tags = {t.ui, "nav", "lsp", "ts"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"aerial".setup {
      -- NOTE: for python, lsp backend doesn't give any hierarchy :/
      --   (any shows many useless items like imports)
      backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
      show_guides = true,
      highlight_on_hover = true, -- FIXME: not respected in Aerial's Nav popup 😬
      -- TODO: 👆 Ideally I'd like to highlight the whole node (like with navbuddy) 🤔
      highlight_on_jump = false,
      layout = {
        default_direction = "prefer_left",
        min_width = 35,
        placement = "edge", -- on the edge of the terminal
      },
      attach_mode = "global", -- display symbols for the current win

      keymaps = {
        -- Disable few default keymaps
        ["<C-j>"] = false, -- clashes with my win nav
        ["<C-k>"] = false, -- clashes with my win nav

        -- Jump & close win
        ["<M-CR>"] = function()
          require"aerial".select()
          require"aerial".close()
        end,

        -- FIXME: I want a simple way to preview whole node for the current item (like navbuddy),
        --   and a simple way to go back to where I was before all the navigation..
        --   (like the navbuddy popup)
        --   (note: `gi` seems to be broken for this 🤬)
        --
        -- IDEA: Make `scroll` & `x_and_scroll` actions _not_ add to jumplist,
        --   so I'm always a <C-O> away from my original position in the buffer
        ["<M-o>"] = "actions.scroll",
        ["<M-v>"] = "actions.jump_vsplit",
        ["<M-s>"] = "actions.jump_split",
        ["<M-t>"] = function()
          -- NOTE: `actions.jump_tab` is missing
          -- .. tracked in https://github.com/stevearc/aerial.nvim/issues/442
          require"aerial".select { split = "tab split" }
        end,
        ["<M-j>"] = "actions.down_and_scroll",
        ["<M-k>"] = "actions.up_and_scroll",
        ["h"] = "actions.prev_up", -- select parent item
        -- BUG: 👆 `prev_up` is relative to the last `scroll`, not relative to the cursor ☹️
        -- .. tracked in https://github.com/stevearc/aerial.nvim/issues/444
        ["l"] = function()
          -- toggle tree, do not attempt to toggle parent
          require"aerial".tree_toggle { bubble = false }
        end,
        ["o"] = function()
          -- toggle tree, do not attempt to toggle parent
          require"aerial".tree_toggle { bubble = false }
        end,
        -- TODO: I want `J`/`K` to jump to next/prev at same level
        -- NOTE: Not possible with the API we have.
        -- .. tracked in https://github.com/stevearc/aerial.nvim/issues/443
      },
      nav = {
        preview = true,
        min_height = { 20, 0.5 },
        win_opts = { winblend = 0 },
        keymaps = {
          -- Disable few default keymaps
          ["<C-j>"] = false, -- clashes with my win nav
          ["<C-k>"] = false, -- clashes with my win nav

          ["q"] = "actions.close",
          ["<esc>"] = "actions.close",

          ["<M-v>"] = "actions.jump_vsplit",
          ["<M-s>"] = "actions.jump_split",
          ["<M-t>"] = function(nav)
            -- impl inspired from aerial's builtin nav actions to `jump_split`.
            -- NOTE: `actions.jump_tab` is missing
            -- .. tracked in https://github.com/stevearc/aerial.nvim/issues/442
            local symbol = nav:get_current_symbol()
            nav:close()
            if symbol then
              require"aerial.navigation".select_symbol(
                symbol,
                nav.winid,
                nav.bufnr,
                { jump = true, split = "tab split" }
              )
            end
          end,
        },
      },
      icons = {
        -- aerial always adds a space after icon
        Module = "{}",
        Namespace = "{}",
        Package = "",
        Interface = "",
        Struct = "",
        Class = "",
        Constructor = "",
        Method = "󰊕",
        Property = "",
        Function = "󰊕",
        Enum = "",
      },
    }
    K.local_leader_map{mode="n", key="cp", desc="Code Nav panel", action=require"aerial".toggle}
  end,
  on_colorscheme_change = function()
    U.hl.set("AerialLine", { link = "Visual" })
  end,
}

Plug {
  source = gh"error311/wayfinder.nvim",
  desc = "Guided code exploration trails from current symbol (shows defs, refs, callers, git info, ..)",
  tags = {t.ui, "lsp", "nav"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require("wayfinder").setup {}
    -- NOTE: exposes many :Wayfinder* commands

    K.local_leader_map_define_group{mode="n", prefix_key="w", name="+wayfinder"}
    K.local_leader_map{mode="n", key="wf", action=vim.cmd.Wayfinder, desc="Wayfinder Open"}
    K.local_leader_map{mode="n", key="wto", action=vim.cmd.WayfinderTrailOpen, desc="Wayfinder Trail Open"}
    K.local_leader_map{mode="n", key="wtt", action=vim.cmd.WayfinderTrailResume, desc="Wayfinder Trail Resume Last"}
  end,
}

Plug {
  source = myplug"smart-bol.nvim",
  desc = "Provide action to cycle movements ^ and 0 with a single key",
  tags = {"movement", t.insert},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    -- I: Move cursor to begin/end of line
    -- NOTE: BREAKS UNDO
    --   I couldn't make the smart-bol plugin work in insert mode in a 'repeat'-able way nor without
    --   breaking undo...
    --   (moving to end could, but having begin/end have different behavior is a no-no)
    --
    -- NOTE: Direct mapping of <M-^> might need special terminal config to work instantly...
    -- otherwise dead key might be triggered (like `^e` to make `ê`).
    -- (wezterm implemented this after my issue: https://github.com/wez/wezterm/issues/877)
    -- vim.cmd[[inoremap <M-^> <C-g>U<Home>]] -- BUT: <Home> moves like 0 not like ^
    local smart_bol_act = require"smart-bol.actions"
    K.toplevel_map{mode={"n", "i"}, key=[[<M-^>]],  desc="smart bol", action=smart_bol_act.do_smart_bol}
    K.toplevel_map{mode={"n", "i"}, key=[[<Home>]], desc="smart bol", action=smart_bol_act.do_smart_bol}
    K.toplevel_map{mode={"n", "i"}, key=[[<M-$>]],  desc="eol", action=[[<End>]]}
  end,
}

Plug {
  source = gh"andymass/vim-matchup",
  desc = "even better % 👊",
  tags = {t.content_ui, t.editing},
  on_load = function()
    -- DISABLE showing off-screen matches (alt: { method = "popup" })
    vim.g.matchup_matchparen_offscreen = {}
    -- In insert mode, after changing text inside a word, matching words will be automatically
    -- changed (if they are supposed to go in pairs).
    -- (experimental @2025-02)
    vim.g.matchup_transmute_enabled = 1
    -- Disable double-click map to select the whole current scope (`va%` works well instead)
    vim.g.matchup_mouse_enabled = 0
    -- DISABLE considering quotes (single/double) as possible matches
    vim.g.matchup_treesitter_enable_quotes = false
    -- DISABLE show virtual text at virtual end of a block
    vim.g.matchup_treesitter_disable_virtual_text = true
  end,
  on_colorscheme_change = function()
    -- parenthesis matches still use the vim standard `MatchParen`
    -- word matches uses `MatchWord` (using `MatchParen` for words is too flashy!)
    U.hl.set("MatchWord", { underline = true })
  end
}
