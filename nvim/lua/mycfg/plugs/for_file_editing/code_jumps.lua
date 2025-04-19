local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { --[[ TODO: fill this! ]] },
}

--------------------------------

Plug {
  source = gh"jremmen/vim-ripgrep",
  desc = "Use RipGrep in Vim and display results in a quickfix list",
  tags = {t.vimscript},
  defer_load = { on_event = "VeryLazy" },
}

Plug {
  source = gh"SmiteshP/nvim-navbuddy",
  desc = "A simple ranger-like popup to navigate LSP document symbols",
  tags = {t.ui, "lsp"}, -- note: Does NOT support Treesitter navigation
  defer_load = { on_event = "VeryLazy" },
  depends_on = {
    Plug { source = gh"SmiteshP/nvim-navic" }, -- NOTE: not auto-enabled, used as a lib
    Plug.lib_nui
  },
  -- NOTE: the plugin supports a bit more than navigation, for example:
  -- - `a` will insert a new thing after/before item
  -- - `c` will comment item
  -- - `r` will rename item
  -- - `J/K` will move node above/below prev/next item
  -- - ...
  on_load = function()
    -- Open with :Navbuddy
    -- FIXME: I want to hide variables, and only focus on structural symbols (fn, class, modules, ..)
    require"nvim-navbuddy".setup {
      lsp = { auto_attach = true },
      icons = {
        File = " ",
        Module = "{}",
        Namespace = "{}",
        Package = " ",
        Class = " ",
        Method = "󰊕 ",
        Property = " ",
        Field = " ",
        Constructor = " ",
        Enum = " ",
        Interface = " ",
        Function = "󰊕 ",
        Variable = " ",
        Constant = " ",
        String = " ",
        Number = " ",
        Boolean = " ",
        Array = "[]",
        Object = "{}",
        Key = " ",
        Null = "∅ ",
        EnumMember = " ",
        Struct = " ",
        Event = " ",
        Operator = " ",
        TypeParameter = " ",
      }
    }

    local_leader_map{mode="n", key="cN", desc="Code LSP Navigation", action=require"nvim-navbuddy".open}

    -- TODO: define type highlights
    -- NavbuddyFunction, ...
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
      },
      keymaps = {
        -- Disable few default keymaps
        ["<C-j>"] = false, -- clashes with my win nav
        ["<C-k>"] = false, -- clashes with my win nav

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
              require("aerial.navigation").select_symbol(
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
    local_leader_map{mode="n", key="cn", desc="Code Nav popup", action=require"aerial".nav_toggle}
    local_leader_map{mode="n", key="cp", desc="Code Nav panel", action=require"aerial".toggle}
  end,
  on_colorscheme_change = function()
    vim.api.nvim_set_hl(0, "AerialLine", { link = "Visual" })
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
    toplevel_map{mode={"n", "i"}, key=[[<M-^>]],  desc="smart bol", action=smart_bol_act.do_smart_bol}
    toplevel_map{mode={"n", "i"}, key=[[<Home>]], desc="smart bol", action=smart_bol_act.do_smart_bol}
    toplevel_map{mode={"n", "i"}, key=[[<M-$>]],  desc="eol", action=[[<End>]]}
  end,
}

Plug {
  source = gh"andymass/vim-matchup",
  desc = "even better % 👊",
  tags = {t.content_ui, t.editing},
  on_load = function()
    -- Disable showing off-screen matches (alt: { method = "popup" })
    vim.g.matchup_matchparen_offscreen = {}
    -- In insert mode, after changing text inside a word, matching words will be automatically
    -- changed (if they are supposed to go in pairs).
    -- (experimental @2025-02)
    vim.g.matchup_transmute_enabled = 1
    -- DO NOT map double-click to select the whole current scope (`va%` works well instead)
    vim.g.matchup_mouse_enabled = 0
  end,
  on_colorscheme_change = function()
    -- parenthesis matches still use the vim standard `MatchParen`
    -- word matches uses `MatchWord` (using `MatchParen` for words is too flashy!)
    vim.api.nvim_set_hl(0, "MatchWord", { underline = true })
  end
}
