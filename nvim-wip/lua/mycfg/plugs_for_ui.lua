local U = require"mylib.utils"
local _f = U.str_space_concat
local _s = U.str_surround
local _q = U.str_simple_quote_surround

local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.MasterDeclarator:get_anonymous_plugin_declarator()
local NamedPlug = PluginSystem.MasterDeclarator:get_named_plugin_declarator()

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.predefined_tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug

--------------------------------

Plug {
  source = myplug"restore-cursor.nvim",
  desc = "Restore cursor when opening file for first time, customizable :)",
  tags = {t.content_ui},
  on_load = function()
    require("restore-cursor").setup()
  end,
}

NamedPlug.statusline {
  source = gh"rebelot/heirline.nvim",
  desc = "Heirline.nvim is a no-nonsense Neovim Statusline plugin",
  -- Very flexible, modular, declarative, dynamic & nicely customizable !!!
  -- Full doc is available at: https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md
  -- (no vim doc for now)
  tags = {t.ui, t.careful_update, t.extensible},
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

    local hline_mycfg = require("mycfg.heirline_statusline_setup")
    heirline.setup(hline_mycfg.get_heirline_setup_opts())
  end,
}

Plug {
  source = gh"folke/which-key.nvim",
  desc = "Display a popup with possible keybindings of the command you started typing",
  tags = {"keys", t.ui},
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

Plug {
  -- Use `:Oil <path>`, use `g?` for help
  source = gh"stevearc/oil.nvim",
  desc = "Edit your filesystem like a normal Neovim buffer",
  tags = {"filesystem"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"oil".setup {
      -- Don't hijack nvim's file explorer, neotree already does that
      -- NOTE: last hijacker wins, so plugin load order is important but my plugins
      --   definition system doesn't support plugin ordering for now..
      default_file_explorer = false,

      keymaps = {
        -- Disable default split/tab actions that use Ctrl 😬
        ["<C-s>"] = false,
        ["<C-h>"] = false,
        ["<C-t>"] = false,
        -- Disable more defaults that use Ctrl 😬
        ["<C-p>"] = false,
        ["<C-l>"] = false,

        ["<M-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<M-h>"] = { "actions.select", opts = { vertical = true } },
        ["<M-t>"] = { "actions.select", opts = { tab = true } },
        ["<M-p>"] = "actions.preview",
        ["<M-r>"] = "actions.refresh",
        ["<BS>"] = "actions.parent",
      },
    }

    toplevel_map{mode={"n"}, key="-", action=[[<cmd>Oil<cr>]], desc="Oil: Open parent dir"}
  end,
}

Plug {
  -- extra-keywords: neotree
  source = gh"nvim-neo-tree/neo-tree.nvim",
  desc = "Neovim plugin to manage the file system and other tree like structures",
  tags = {t.ui, "filesystem", "nav"},
  version = { branch = "v3.x" },
  depends_on = {NamedPlug.lib_plenary, NamedPlug.lib_nui, NamedPlug.lib_web_devicons},
  defer_load = { on_cmd = "Neotree" },
  on_load = function()
    require("neo-tree").setup {
      sources = {
        "filesystem", -- builtin
        "buffers", -- builtin
        "git_status", -- builtin
      },
      default_source = "filesystem",
      use_popups_for_input = false, -- force use vim.input
      sort_case_insensitive = true,
      source_selector = {
        winbar = true,
        -- BROKEN: opened issue: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/848
        -- tabs_layout = "start",
        content_layout = "center",
      },
      -- Default window configs (can be specialized per source)
      window = {
        position = "right",
        mappings = {
          -- Action names are found in:
          -- common actions: <plug>/lua/neo-tree/sources/common/commands.lua
          -- per-source actions, e.g: <plug>/lua/neo-tree/sources/filesystem/commands.lua
          -- FIXME: how to define custom ad-hoc actions here in the config?
          -- FIXME: missing tree navigation actions to goto parent node, goto next/prev sibling node
          ["a"] = {"add", config = { show_path = "relative" }},
          ["o"] = "open",
          ["t"] = "noop", ["s"] = "noop", ["S"] = "noop", -- disable default split/tab opening keys
          ["<M-t>"] = "open_tabnew",
          ["<M-s>"] = "open_split",
          ["<M-v>"] = "open_vsplit",

          ["z"] = "noop",
          ["zC"] = "close_all_nodes",
          -- ["zA"] = "expand_all_nodes", -- BROKEN: crashes neovim :eyes:
        },
      },
      -- event_handlers = {},
      default_component_configs = {
        name = {
          trailing_slash = true,
        }
      },

      -- Per source configs
      filesystem = {
        bind_to_cwd = false, -- don't change tab cwd when opening Neotree with a dir
        group_empty_dirs = true,
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false, -- AFAIU, 'false' -> dirs that were not manually opened will be auto-closed
        },
        window = {
          mappings = {
            -- Disable neotree's fuzzy finder on `/`, it's annoying when I just want to jump to something I see
            ["/"] = "noop",
            ["#"] = "noop",
            -- Re-enable neotree's fuzzy finder using shifted letters so I can spam shift `/` + shift
            -- `f` to activate it, but still do shift `/` + `bla` to search `bla` with vim's search.
            ["/F"] = "fuzzy_finder",
            ["//"] = "fuzzy_finder", -- alt mapping, nicer?
            ["/D"] = "fuzzy_finder_directory", -- only directories
            -- FIXME: how to make the fuzzy_finder NOT auto-open found file?
            --   (when pressing <cr> after searching something to hide)
            --   => Then, how to hide results? Maybe with an empty fuzzy search? (not great..)
            -- NOTE: I'd expect the fuzzy finder thing to not be specific to filesystem view,
            --   and to work over any sets of tree of nodes
            -- FIXME: how to close the fuzzy_finder searchbox while keeping the filtered view of
            --   results??
          },
          fuzzy_finder_mappings = {
            ["<M-j>"] = "move_cursor_down",
            ["<M-k>"] = "move_cursor_up",
          },
        },
      },
      git_status = {
        bind_to_cwd = false, -- don't change tab cwd when opening Neotree with a dir
      },
      buffers = {
        bind_to_cwd = false, -- don't change tab cwd when opening Neotree with a dir
      },
    }
  end,
  on_colorscheme_change = function()
    -- Necessary as I don't have 'termguicolor' => ~all default colors are not available
    vim.cmd[[hi NeoTreeModified cterm=bold]]
    vim.cmd[[hi NeoTreeDimText ctermfg=239]]
    vim.cmd[[hi NeoTreeTabActive cterm=bold]]
    vim.cmd[[hi NeoTreeTabInactive ctermfg=239]]
    vim.cmd[[hi NeoTreeTabSeparatorInactive ctermfg=239]]
  end
}

NamedPlug.startup_screen {
  source = gh"goolord/alpha-nvim",
  desc = "a lua powered greeter like vim-startify / dashboard-nvim",
  tags = {t.ui, t.extensible},
  depends_on = {NamedPlug.lib_web_devicons},
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

NamedPlug.telescope {
  source = gh"nvim-telescope/telescope.nvim",
  desc = "Find, Filter, Preview, Pick. All lua, all the time…",
  tags = {"nav"},
  -- FIXME: install native sorter!
  depends_on = {NamedPlug.lib_plenary},
  config_depends_on = {
    Plug { source = gh"nvim-telescope/telescope-ui-select.nvim" },
    Plug { source = gh"nvim-telescope/telescope-frecency.nvim" },
    Plug { source = gh"OliverChao/telescope-picker-list.nvim" },
    Plug { source = gh"piersolenski/telescope-import.nvim" },
  },
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local tel_actions = require"telescope.actions"
    local tel_actions_lay = require"telescope.actions.layout"
    local action_state = require"telescope.actions.state"
    local wrap_tel_action_fn = function(action_name, fn)
      return require"telescope.actions.mt".transform_mod({[action_name] = fn})[action_name]
    end
    local default_cfg = {}
    -- DEFAULT (my) MAPPINGS
    default_cfg.default_mappings = {} -- disable all default mappings
    -- Available actions:
    -- - https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac/lua/telescope/actions/init.lua
    -- - https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac/lua/telescope/actions/layout.lua
    -- Default mappings:
    -- - https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac/lua/telescope/mappings.lua#L133
    default_cfg.mappings = {n = {}, i = {}}
    -- Telescope doesn't support adding to both modes at the same time
    -- so we'll add common mappings after all others.
    local both_n_i = {
      -- Close on empty prompt
      ["<C-d>"] = wrap_tel_action_fn("close_on_empty_prompt", function(prompt_bufnr)
        local prompt = action_state.get_current_line()
        -- print("DEBUG", "prompt text:", vim.inspect(prompt), "len:", #prompt)
        if #prompt == 0 then
          tel_actions.close(prompt_bufnr)
        else
          vim.notify("Cannot close, prompt is not empty")
        end
      end),

      -- N/I: Select actions
      ["<CR>"] = tel_actions.select_default,
      ["<C-j>"] = tel_actions.select_default,
      -- FIXME: multi-selection not handled properly FIXME :/
      ["<M-s>"] = tel_actions.select_horizontal,
      ["<M-v>"] = tel_actions.select_vertical,
      ["<M-t>"] = tel_actions.select_tab,
      -- FIXME: what's the diff between file_* & select_* actions?

      -- N/I: Move selection
      ["<Down>"] = tel_actions.move_selection_next,
      ["<Up>"] = tel_actions.move_selection_previous,

      -- N/I: Manage multi-selection
      ["<C-a>"] = tel_actions.toggle_all,
      ["<C-c>"] = tel_actions.drop_all,
      ["<M-a>"] = tel_actions.toggle_selection + tel_actions.move_selection_worse,
      ["<M-Space>"] = tel_actions.toggle_selection,

      -- N/I: Results up/down scrolling
      ["<M-K>"] = tel_actions.results_scrolling_up,
      ["<M-J>"] = tel_actions.results_scrolling_down,

      -- N/I: Preview up/down scrolling
      ["<C-M-k>"] = tel_actions.preview_scrolling_up,
      ["<C-M-j>"] = tel_actions.preview_scrolling_down,

      -- N/I: History nav
      ["<C-n>"] = tel_actions.cycle_history_next,
      ["<C-p>"] = tel_actions.cycle_history_prev,

      -- N/I: Integration with quickfix list (send/add)
      ["<M-q>"] = tel_actions.send_selected_to_qflist + tel_actions.open_qflist,
      ["<C-M-q>"] = tel_actions.add_selected_to_qflist + tel_actions.open_qflist, -- (?)

      -- N/I: Layout actions
      ["<C-M-P>"] = tel_actions_lay.toggle_preview,
      ["<C-f>"] = wrap_tel_action_fn("toggle_fullscreen", function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        if vim.b[prompt_bufnr].telescope_last_layout_config then
          -- Restore layout config, out of fullscreen!
          picker.layout_config = vim.b[prompt_bufnr].telescope_last_layout_config
          -- print("DEBUG", "restoring layout config:", vim.inspect(picker.layout_config))
          vim.b[prompt_bufnr].telescope_last_layout_config = nil
        else
          -- Save layout config, set fullscreen!
          -- print("DEBUG", "saving layout config:", vim.inspect(picker.layout_config))
          vim.b[prompt_bufnr].telescope_last_layout_config = vim.deepcopy(picker.layout_config)
          -- Set current layout strategy size to (almost) 100% (note: 1.0 doesn't work…)
          picker.layout_config[picker.layout_strategy].height = 0.99
          picker.layout_config[picker.layout_strategy].width = 0.99
        end
        picker:full_layout_update()
      end),

      -- N/I: Mouse actions
      ["<LeftMouse>"] = {
        tel_actions.mouse_click,
        type = "action",
        opts = { expr = true },
      },
    }
    default_cfg.mappings.i = {
      ["<M-Esc>"] = tel_actions.close,

      -- Move selection
      ["<M-j>"] = tel_actions.move_selection_next,
      ["<M-k>"] = tel_actions.move_selection_previous,
      ["<M-g>"] = tel_actions.move_to_top,
      ["<M-G>"] = tel_actions.move_to_bottom,

      -- Insert file/line/cword
      ["<C-r><C-f>"] = tel_actions.insert_original_cfile,
      ["<C-r><C-l>"] = tel_actions.insert_original_cline,
      ["<C-r><C-w>"] = tel_actions.insert_original_cword,
      ["<C-r><C-a>"] = tel_actions.insert_original_cWORD,
    }
    default_cfg.mappings.n = {
      ["<esc>"] = tel_actions.close,
      ["?"] = tel_actions.which_key,

      -- Move selection
      ["j"] = tel_actions.move_selection_next,
      ["k"] = tel_actions.move_selection_previous,
      ["g"] = tel_actions.move_to_top,
      -- ["M"] = tel_actions.move_to_middle,
      ["G"] = tel_actions.move_to_bottom,

      -- Results up/down/left/right scrolling
      ["<PageUp>"] = tel_actions.results_scrolling_up,
      ["<PageDown>"] = tel_actions.results_scrolling_down,
      ["<K>"] = tel_actions.results_scrolling_up,
      ["<J>"] = tel_actions.results_scrolling_down,
      ["H"] = tel_actions.results_scrolling_left,
      ["L"] = tel_actions.results_scrolling_right,
    }
    -- Add mappings common for both modes:
    for _, mode in ipairs{"i", "n"} do
      for key, mapping in pairs(both_n_i) do
        default_cfg.mappings[mode][key] = mapping
      end
    end

    -- DEFAULT LAYOUT
    default_cfg.layout_config = {
      prompt_position = "top",
    }
    default_cfg.sorting_strategy = "ascending" -- make sure results are from top-to-bottom
    default_cfg.scroll_strategy = "limit" -- (not cycle!)
    default_cfg.borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" } -- heavier borders
    -- // some ideas..
    -- heavy single border: { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" }
    -- half blocks (outer): { "▀", "▐", "▄", "▌", "▛", "▜", "▟", "▙" }
    -- half blocks (inner): { "▄", "▌", "▀", "▐", "▗", "▖", "▘", "▝" }
    -- thin blocks: { "▔", "▕", "▁", "▏", "🭽", "🭾", "🭿", "🭼" }

    local extensions_cfg = {}
    local extensions_to_load = {}

    -- Extension: fzf
    extensions_cfg.fzf = {} -- default config
    vim.cmd.packadd"telescope-fzf-native" -- from Nix-managed plugins (has native pkg!)
    table.insert(extensions_to_load, "fzf")

    -- Extension: ui-select
    extensions_cfg["ui-select"] = {
      require('telescope.themes').get_dropdown(),
    }
    table.insert(extensions_to_load, "ui-select")

    -- Extension: frecency
    extensions_cfg.frecency = {
      matcher = "fuzzy",
    }
    table.insert(extensions_to_load, "frecency")

    -- Extension: import (find imports in files around)
    extensions_cfg.import = {} -- default config
    table.insert(extensions_to_load, "import")

    -- Extension: picker_list
    -- /!\ must be the last extension
    extensions_cfg.picker_list = {
      -- ignore some pickers I don't need here
      excluded_pickers = {
        "fzf", -- native searcher
        "fd", -- alias for find_files
        "grep_string", -- live_grep is better
        "tags", "current_buffer_tags", -- never use tags now..
        "git_files", -- find_files is basically the same.. (with fd-based finder)
      },
    }
    table.insert(extensions_to_load, "picker_list")

    require"telescope".setup {
      extensions = extensions_cfg,
      defaults = default_cfg,
      pickers = {
        colorscheme = {
          ignore_builtins = true,
          enable_preview = true,
        },
      },
    }
    -- Load extensions
    for _, ext_name in ipairs(extensions_to_load) do
      require"telescope".load_extension(ext_name)
    end

    local tel_builtin = require"telescope.builtin"

    -- Direct key for most used search!
    toplevel_map{mode={"n"}, key="<M-f>", desc="Fuzzy search files", action=tel_builtin.find_files}
    toplevel_map{mode={"n"}, key="<M-F>", desc="Fuzzy search _all_ files", action=function()
      tel_builtin.find_files { no_ignore = true }
    end}

    toplevel_map_define_group{mode={"n"}, prefix_key="<C-f>", name="+Fuzzy search"}
    toplevel_map{mode={"n"}, key="<C-f><C-f>", desc="… Resume last", action=tel_builtin.resume} -- ✨
    toplevel_map{mode={"n"}, key="<C-f><C-z>", desc="Pick a picker…", action=function() vim.cmd.Telescope("picker_list") end}
    toplevel_map{mode={"n"}, key="<C-f><C-g>", desc="Live Grep", action=tel_builtin.live_grep} -- use C-Space to fuzzy refine
    toplevel_map{mode={"n"}, key="<C-f><C-r>", desc="Frecency", action=function() vim.cmd.Telescope("frecency") end}
    toplevel_map{mode={"n"}, key="<C-f><C-m>", desc="Commands", action=tel_builtin.commands} -- note: <C-f><C-c> broken 🤔
    toplevel_map{mode={"n"}, key="<C-f><C-h>", desc="Help Tags", action=tel_builtin.help_tags}
    toplevel_map{mode={"n"}, key="<C-f><C-j>", desc="Jumps", action=tel_builtin.jumplist}
    toplevel_map{mode={"n"}, key="<C-f><C-l>", desc="Buffer lines", action=tel_builtin.current_buffer_fuzzy_find}
    toplevel_map{mode={"n"}, key="<C-f><C-Space>", desc="Buffers", action=tel_builtin.buffers}
  end,
  on_colorscheme_change = function()
    local function get_hl(name)
      return vim.api.nvim_get_hl(0, { name = name })
    end
    local normal = get_hl"Normal"
    local cols = {}
    cols.TelescopeBorder = normal
    cols.TelescopePromptBorder = {
      ctermfg = 202,
      ctermbg = normal.ctermbg,
    }
    -- Titles are the reverse of borders
    cols.TelescopeTitle = vim.tbl_extend("force", cols.TelescopeBorder, { reverse = true, bold = true })
    cols.TelescopePromptTitle = vim.tbl_extend("force", cols.TelescopePromptBorder, { reverse = true, bold = true })

    cols.TelescopeMatching = { ctermfg = 202 }
    cols.TelescopeMultiSelection = { ctermbg = 22, bold = true }

    for hlgroup, hlspec in pairs(cols) do
      vim.api.nvim_set_hl(0, hlgroup, hlspec)
    end
  end
}

Plug {
  source = gh"NStefan002/screenkey.nvim",
  desc = "Screencast your keys",
  tags = {"keys", t.ui},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"screenkey".setup {
      clear_after = 30, -- in seconds
      group_mappings = true,
    }

    my_actions.screencast_toggle = mk_action_v2 {
      default_desc = "Toggle keys screencast",
      n = function()
        vim.cmd.Screenkey("toggle")
      end
    }
  end
}

Plug {
  source = gh"0xAdk/full_visual_line.nvim",
  desc = "Highlights whole lines in linewise visual mode",
  tags = {t.content_ui},
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
  tags = {t.content_ui},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"visual-whitespace".setup {
      highlight = {
        ctermfg = vim.api.nvim_get_hl(0, {name="Comment"}).ctermfg,
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
  source = gh"sphamba/smear-cursor.nvim",
  desc = "Animate the cursor with a smear/trail effect in all terminals",
  tags = {t.content_ui},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"smear_cursor".setup {
      -- config: https://github.com/sphamba/smear-cursor.nvim/blob/main/lua/smear_cursor/config.lua
      legacy_computing_symbols_support = true,
      distance_stop_animating = 3, -- don't animate when target is this close
      -- cursor_color = "#ff8800", -- FIXME: Cursor color need _RGB_ colors for that
      color_levels = 5, -- limit color range, see below for color256 palettes

      -- trailing_stiffness = 0.02, -- DEBUG: much slower trail (0.02-0.05)
    }
  end,
  on_colorscheme_change = function()
    -- @2024-12 the plugin doesn't expose a way to customize hl groups as they are created
    -- on-the-fly based on various RGB colors (not terminal colors).
    -- So we need to get creative, and manually trigger group creation and override them.
    -- REF: https://github.com/sphamba/smear-cursor.nvim/issues/50#issuecomment-2525347852
    local config = require("smear_cursor.config")
    local color = require("smear_cursor.color")
    for i = 1, config.color_levels do
      color.get_hl_group({ level = i })
      -- note: my config doesn't seem to ever use the inverted color groups
      -- color.get_hl_group({ level = i, inverted = true })
    end
    -- WARN: assert(#palette == config.color_levels) !
    local smear_palette_fire = {
      { ctermfg = 137 },
      { ctermfg = 136 },
      { ctermfg = 130 },
      { ctermfg = 130 },
      { ctermfg = 166 },
    }
    local smear_palette_darkwhite = {
      { ctermfg = 235 },
      { ctermfg = 240 },
      { ctermfg = 245 },
      { ctermfg = 245 },
      { ctermfg = 255 },
    }
    local smear_palette = smear_palette_fire
    for i, hl_spec in ipairs(smear_palette) do
      vim.api.nvim_set_hl(0, "SmearCursorNormal"..i, hl_spec)
    end
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

Plug {
  source = gh"jremmen/vim-ripgrep",
  desc = "Use RipGrep in Vim and display results in a quickfix list",
  tags = {t.vimscript, "nav"},
  defer_load = { on_event = "VeryLazy" },
}

-- FIXME: 'mbbill/undotree' does NOT have diff preview when going up/down :/
-- Best would be 'simnalamburt/vim-mundo' BUT it requires python...
-- See: https://github.com/nvim-lua/wishlist/issues/21
Plug {
  source = gh"mbbill/undotree",
  desc = "Vim undo tree visualizer",
  tags = {t.vimscript, t.ui, t.need_better_plugin},
  defer_load = { on_cmd = "UndotreeToggle" },
  -- pre_load because it must be set before `plugin/` files are loaded!
  on_pre_load = function()
    -- (e.g) Use 'd' instead of 'days' to save some space.
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SplitWidth = 42
  end,
  on_load = function()
    toplevel_map{mode={"n"}, key="<F5>", action=[[:UndotreeToggle<cr>]], desc="Toggle undo tree"}
  end,
}

Plug {
  source = gh"2KAbhishek/nerdy.nvim",
  desc = "UI to find nerd-font glyphs easily",
  tags = {"utils", t.ui},
  defer_load = { on_event = "VeryLazy" },
}

Plug {
  source = gh"vim-scripts/xterm-color-table.vim",
  desc = "Provide some commands to display all cterm colors",
  tags = {"utils", t.ui, t.vimscript},
  defer_load = { on_event = "VeryLazy" },
}

--------------------------------

NamedPlug.lib_web_devicons {
  source = gh"kyazdani42/nvim-web-devicons",
  desc = "Find (colored) icons for file type",
  tags = {t.ui, t.lib_only},
  defer_load = { autodetect = true },
  on_load = function()
    require'nvim-web-devicons'.set_default_icon("", "#cccccc", 244)
    require'nvim-web-devicons'.setup { default = true } -- give a default icon when nothing matches
  end,
}

NamedPlug.lib_nui {
  source = gh"MunifTanjim/nui.nvim",
  desc = "UI Component Library for Neovim",
  tags = {t.ui, t.lib_only},
  defer_load = { autodetect = true },
}
