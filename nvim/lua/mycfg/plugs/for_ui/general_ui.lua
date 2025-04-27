local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
-- local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui },
}

local A = require"mylib.action_system"
local K = require"mylib.keymap_system"

--------------------------------

Plug.statusline {
  source = gh"rebelot/heirline.nvim",
  desc = "Heirline.nvim is a no-nonsense Neovim Statusline plugin",
  -- Very flexible, modular, declarative, dynamic & nicely customizable !!!
  -- Full doc is available at: https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md
  -- (no vim doc for now)
  tags = {t.careful_update},
  config_depends_on = {
    Plug {
      source = gh"Zeioth/heirline-components.nvim",
      version = { tag = "v1.1.2" }, -- For support for nvim <0.10
      defer_load = { on_event = "UIEnter" }, -- same as heirline
    },
  },
  defer_load = { on_event = "UIEnter" },
  on_load = function()
    local heirline = require"heirline"
    local external_heirline_components = require "heirline-components.all"

    heirline.load_colors(external_heirline_components.hl.get_colors())
    vim.api.nvim_create_autocmd("ColorScheme", {
      desc = "Re-apply heirline colors",
      callback = function()
        local hl = require"heirline-components.core.hl"
        require"heirline.utils".on_colorscheme(hl.get_colors())
      end,
    })

    local hline_mycfg = require"mycfg.heirline_statusline_setup"
    heirline.setup(hline_mycfg.get_heirline_setup_opts())
  end,
}

Plug {
  source = gh"sphamba/smear-cursor.nvim",
  desc = "Animate the cursor with a smear/trail effect in all terminals",
  tags = {"hint"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    -- NOTE: to get nice color highlight my config requires need to have `ctermfg = number` text,
    -- but smear config wants a list of numbers, so I made these lists to have highlights ;)
    local smear_palettes = {}
    smear_palettes.fire = {
      { ctermfg = 179 },
      { ctermfg = 179 },
      { ctermfg = 136 },
      { ctermfg = 136 },
      { ctermfg = 166 },
      { ctermfg = 166 },
    }
    smear_palettes.black_and_white = {
      { ctermfg = 235 },
      { ctermfg = 240 },
      { ctermfg = 243 },
      { ctermfg = 250 },
      { ctermfg = 255 },
    }
    require"smear_cursor".setup {
      -- REF for config options:
      -- https://github.com/sphamba/smear-cursor.nvim/blob/main/lua/smear_cursor/config.lua
      legacy_computing_symbols_support = true,

      -- Disable trail in some cases:
      -- .. for tiny horizontal/vertical movements
      min_horizontal_distance_smear = 4,
      min_vertical_distance_smear = 3,
      -- .. in insert mode, it looks pretty bad :/
      smear_insert_mode = false,
      -- .. in cmdline, as it prevents builtin behavior where I can write 2
      -- commands and still see the result of the first command.
      -- (which is very useful when editing hl or exploring options)
      smear_to_cmd = false,

      -- New default (false) looks pretty bad when termguicolors is disabled..
      -- ref: https://github.com/sphamba/smear-cursor.nvim/issues/125
      never_draw_over_target = true,

      cterm_cursor_colors = vim.tbl_map(function(it) return it.ctermfg end, smear_palettes.fire),
      -- trailing_stiffness = 0.04, -- DEBUG: much slower trail (0.02-0.07 are great)
    }
  end,
}

-- FIXME: 'mbbill/undotree' does NOT have diff preview when going up/down :/
-- Best would be 'simnalamburt/vim-mundo' BUT it requires python...
-- See: https://github.com/nvim-lua/wishlist/issues/21
Plug {
  source = gh"mbbill/undotree",
  desc = "Vim undo tree visualizer",
  tags = {t.vimscript, t.need_better_plugin},
  defer_load = { on_cmd = "UndotreeToggle" },
  -- pre_load because it must be set before `plugin/` files are loaded!
  on_pre_load = function()
    -- (e.g) Use 'd' instead of 'days' to save some space.
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SplitWidth = 42
  end,
  on_load = function()
    K.toplevel_map{mode={"n"}, key="<F5>", action=[[:UndotreeToggle<cr>]], desc="Toggle undo tree"}
  end,
}

Plug {
  source = gh"2KAbhishek/nerdy.nvim",
  desc = "UI to find nerd-font glyphs easily",
  tags = {"utils"},
  defer_load = { on_event = "VeryLazy" },
}

Plug {
  source = gh"vim-scripts/xterm-color-table.vim",
  desc = "Provide some commands to display all cterm colors",
  tags = {"utils", t.vimscript},
  defer_load = { on_event = "VeryLazy" },
}

Plug {
  source = gh"folke/which-key.nvim",
  desc = "Display a popup with possible keybindings of the command you started typing",
  tags = {"keys", "hint"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local wk = require"which-key"
    wk.setup {
      delay = function()
        -- Don't popup helper window until N milliseconds passed without key continuation
        return 1000
      end,
      layout = {
        -- align = "center", -- (!!) no alternative..
        spacing = 5, -- spacing between columns
        -- Make better use of horizontal space
        -- Ref: https://github.com/folke/which-key.nvim/issues/195
        height = { min = 1 },
      },
      icons = {
        separator = "->",
        keys = {
          C = "C-",
          M = "M-",
          D = " ",
          S = "󰘶 ",
          CR = "󰌑 ",
          Esc = "󱊷 ",
          NL = "󰌑 ",
          BS = "󰁮 ",
          Space = "󱁐",
          Tab = "TAB",
        },
      },
      plugins = {
        -- Enable spelling popup on `z=`
        spelling = { enabled = true },
        -- Disable most presets (auto-doc for builtin keys) which assume the default keys
        -- are used. It is distractful, and doesn't detect everything right.
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
        },
      },
      triggers = {
        { "<auto>", mode = "nxo" },
      },
      -- Start hidden and wait for a key to be pressed before showing the popup
      defer = function(ctx)
        -- Always defer in all visual modes
        return ctx.mode:lower() == "v" or ctx.mode == "<C-V>"
      end,
    }

    -- Register groups defined before plugin was available
    wk.add(wk_groups_lazy)
  end,
  on_colorscheme_change = function()
    vim.cmd[[hi WhichKey      ctermfg=33 cterm=bold]]
    vim.cmd[[hi WhichKeyDesc  ctermfg=172]]
    vim.cmd[[hi WhichKeyGroup ctermfg=70]]
  end,
}

Plug.startup_screen {
  source = gh"goolord/alpha-nvim",
  desc = "a lua powered greeter like vim-startify / dashboard-nvim",
  tags = {},
  depends_on = {Plug.lib_web_devicons},
  defer_load = { on_event = "VimEnter" },
  on_load = function()
    -- the plugin is very versatile! ref: https://github.com/goolord/alpha-nvim/discussions/16
    -- simple theme, until I want to make my own...
    local theme = require"alpha.themes.startify"
    -- (NOTE: 'theme.section.footer' is a block of type 'group')
    theme.section.footer.val = {
      { type = "padding", val = 1 },
      { type = "text", val = {" ----------------------------------------------------"} },
      {
        type = "text",
        val = require"alpha.fortune"() -- TODO(later): format with cowsay!
        -- FIXME: static for now, I'd like to generate a new one on demand!
      },
    }
    require"alpha".setup(theme.config)
  end,
}

Plug {
  source = gh"NStefan002/screenkey.nvim",
  desc = "Screencast your keys",
  tags = {"keys"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"screenkey".setup {
      clear_after = 30, -- in seconds
      group_mappings = true,
    }

    my_actions.screencast_toggle = A.mk_action {
      default_desc = "Toggle keys screencast",
      n = function()
        vim.cmd.Screenkey("toggle")
      end
    }
  end
}

Plug {
  source = gh"stevearc/quicker.nvim",
  desc = "Improved UI and workflow for the Neovim quickfix",
  tags = {},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"quicker".setup {
      on_qf = function()
        K.toplevel_buf_map{mode="n", key=[[zo]], desc="More context lines", action=function()
          require"quicker".expand { before = 1, after = 1, add_to_existing = true }
        end}
        K.toplevel_buf_map{mode="n", key=[[zi]], desc="Less context lines", action=function()
          require"quicker".collapse()
        end}
        K.local_leader_buf_map{mode="n", key=[[qe]], desc="Make editable ('till save)", action=function()
          require"quicker.editor".setup_editor(0)
        end}
      end,
      -- enable edits only on-demand (see keys)
      edit = { enabled = false },
      max_filename_width = function()
        return math.floor(math.min(50, vim.o.columns / 3))
      end,
    }
  end,
}
