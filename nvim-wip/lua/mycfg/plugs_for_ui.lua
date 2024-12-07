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
      layout = {
        align = "center",
        spacing = 5,
        height = { min = 1 }, -- Ref: https://github.com/folke/which-key.nvim/issues/195
      },
      icons = { separator = "->" },
      key_labels = {
        -- Override the label used to display some keys
        ["<C-Space>"] = "C-SPC",
        ["<Space>"] = "SPC",
        ["<tab>"] = "TAB",
        ["<cr>"] = "Enter",
        ["<NL>"] = "<C-J>",
      },
      plugins = {
        -- Enable spelling popup on 'z='
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
      -- Ensure the which-key popup is auto-triggered ONLY for a very limited set of keys,
      -- because the popup is mostly annoying/distractful for other keys.
      -- IDEA: possible to show which-key when timeout-ing `operator` mode?
      triggers = {
        "<Leader>",
        "<LocalLeader>", -- FIXME: Sometimes broken, see: https://github.com/folke/which-key.nvim/issues/476
        "z", -- (help for 'z' can be useful) -- FIXME: need grouping!

        "<C-f>", -- fuzzy stuff
        -- NOTE: 'cr' isn't supported here for some reason..
        --   so I have to register the key to trigger which-key myself (see just below)
      },
    }
    toplevel_map{mode={"n"}, key="cr", action=function()
      wk.show("cr", {mode = "n", auto = true})
    end, desc="+coerce"}
    -- Register nmap/vmap keys descriptions
    wk.register(wk_toplevel_n_maps, { mode = "n" })
    wk.register(wk_toplevel_v_maps, { mode = "v" })
    -- TODO: Create a per-buffer map, to avoid crashing WhichKey when the variable
    -- does not exist, we must create a buffer dict, empty for most files,
    -- which will be filled for some file types
    -- FIXME: This does NOT work, because vim-which-key does NOT merge the
    --        dicts of multiple register('same-prefix', different-dict).
    -- autocmd BufRead * let b:which_key_map = {}
    -- autocmd User PluginsLoaded call which_key#register("<space>", "b:which_key_map")
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
  defer_load = { on_cmd = "Oil" },
  on_load = function()
    require"oil".setup {
      -- Don't hijack nvim's file explorer, neotree already does that
      -- NOTE: last hijacker wins, so plugin load order is important but my plugins
      --   definition system doesn't support plugin ordering for now..
      default_file_explorer = false,
    }
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

NamedPlug.fzf_ctrl {
  source = gh"vijaymarupudi/nvim-fzf",
  desc = "A powerful Lua API for using fzf in neovim",
  tags = {"nav"},
  defer_load = { autodetect = true },
  on_load = function()
    require"fzf".default_options = {
      relative = "editor", -- open a centered floating win
      width = 90, -- FIXME: not a percentage!!!! Ask to allow function here?
      height = 40, -- FIXME: not a percentage!!!! Ask to allow function here?
      border = "single",
    }
  end,
}
Plug {
  -- TODO: Use https://github.com/nvim-telescope/telescope.nvim (more flexible!)
  source = gh"ibhagwan/fzf-lua",
  desc = "Few pre-configured thing selectors (buffers, files, ...)",
  tags = {"nav"},
  depends_on = {NamedPlug.fzf_ctrl},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local act = require"fzf-lua.actions"
    local fzf = require"fzf-lua"
    fzf.setup {
      winopts = {
        border = "single",
        preview = {
          default = "bat", -- instead of builtin one, using nvim buffers
        },
      },
      fzf_opts = {}, -- don't let them overwrite my own config!
      keymap = {
        builtin = {
          -- :tmap mappings for the fzf win
          ["<M-p>"] = "toggle-preview", -- to work for builtin previewer
          ["<M-f>"] = "toggle-fullscreen", -- works for all previewers! Fullscreens the terminal, not fzf
        },
        -- don't let them overwrite my own config! (e.g: their alt-a means select all :/)
        fzf = {},
      },
      actions = {
        files = {
          -- keys for all providers that act on files
          ["default"] = act.file_edit,
          ["alt-s"]   = act.file_split,
          ["alt-v"]   = act.file_vsplit,
          ["alt-t"]   = act.file_tabedit,
          ["alt-q"]   = act.file_sel_to_qf, -- this is interesting! (TODO: similar to arglist?)
        },
      },
    }
    fzf.register_ui_select()

    -- Direct key for most used search!
    -- TODO: keep history of selected files! (to easily re-select something!)
    toplevel_map{mode={"n"}, key="<M-f>", desc="Fuzzy search files", action=fzf.files}

    toplevel_map_define_group{mode={"n"}, prefix_key="<C-f>", name="+Fuzzy search"}
    toplevel_map{mode={"n"}, key="<C-f><C-f>", desc="resume last search", action=fzf.resume} -- ❤️
    toplevel_map{mode={"n"}, key="<C-f><C-g>", desc="git files", action=fzf.git_files}
    toplevel_map{mode={"n"}, key="<C-f><C-o>", desc="old files", action=fzf.oldfiles}
    toplevel_map{mode={"n"}, key="<C-f><C-h>", desc="help tags", action=fzf.help_tags}
    toplevel_map{mode={"n"}, key="<C-f><C-j>", desc="jumps", action=fzf.jumps}
    toplevel_map{mode={"n"}, key="<C-f><C-i>", desc="highlight groups", action=fzf.highlights}

    toplevel_map_define_group{mode={"n"}, prefix_key="<C-M-f>", name="+Fuzzy search (alt)"} -- for easy spam <C-M-f><C-M-b>
    buffers_action = function()
      fzf.buffers { previewer = "builtin" } -- syntax highlighting for free (buffer opened!)
    end
    toplevel_map{mode={"n"}, key="<C-f><C-M-b>" --[[C-b used by tmux!]], desc="buffers", action=buffers_action}
    toplevel_map{mode={"n"}, key="<C-M-f><C-M-b>" --[[easy spam!]], desc="buffers", action=buffers_action}

    toplevel_map{mode={"n"}, key="<C-f><C-l>", desc="current buffer lines", action=function()
      fzf.blines {
        -- Don't pre-open the preview (the lines are already my preview)
        winopts = {
          preview = { hidden = "hidden" },
        },
        -- When I want some context I can re-enable the preview and see lines around
        -- (with current line highlighted)
        previewer = "builtin", -- syntax highlighting for free (buffer already opened!)
      }
    end}
  end,
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
  -- Last release (@2024-12-07) has stable impl, `main` branch has a new impl that's not polished yet
  -- Follow: https://github.com/sphamba/smear-cursor.nvim/issues/47
  -- Diff mentioned in: https://github.com/sphamba/smear-cursor.nvim/issues/48#issuecomment-2522295672
  version = { tag = "v0.2.0" },
  tags = {t.content_ui},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"smear_cursor".setup {
      -- config: https://github.com/sphamba/smear-cursor.nvim/blob/main/lua/smear_cursor/config.lua
      legacy_computing_symbols_support = true,
      -- cursor_color = "#ff8800", -- FIXME: Cursor color need _RGB_ colors for that
      distance_stop_animating = 2, -- don't animate when target is this close
    }
  end
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
