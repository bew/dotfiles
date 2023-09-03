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
  tags = {t.code_ui},
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
  on_load = function()
    require("mycfg.heirline_statusline_setup").setup()
  end,
}

Plug {
  source = gh"folke/which-key.nvim",
  desc = "Display a popup with possible keybindings of the command you started typing",
  tags = {"keys", t.ui},
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
        ["<space>"] = "SPC",
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
      triggers = {
        "<leader>",
        "z", -- (help for 'z' can be useful)
        "<M-f>", -- fuzzy stuff
      },
    }
    -- Register nmap/vmap keys descriptions
    wk.register(wk_toplevel_n_maps, { mode = "n" })
    wk.register(wk_toplevel_v_maps, { mode = "v" })
    toplevel_map{mode={"n"}, key="cr", action=function()
      wk.show("cr", {mode = "n", auto = true})
    end, desc="+coerce"}
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
  -- extra-keywords: neotree
  source = gh"nvim-neo-tree/neo-tree.nvim",
  desc = "Neovim plugin to manage the file system and other tree like structures",
  tags = {t.ui, "filesystem", "nav"},
  version = { branch = "v3.x" },
  depends_on = {NamedPlug.lib_plenary, NamedPlug.lib_nui, NamedPlug.lib_web_devicons},
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
          },
          fuzzy_finder_mappings = {
            ["<M-j>"] = "move_cursor_down",
            ["<M-k>"] = "move_cursor_up",
          },
        },
      }
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

Plug {
  enable = false,
  source = gh"kyazdani42/nvim-tree.lua",
  desc = "file explorer tree",
  tags = {t.ui, "filesystem"},
  on_load = function()
    require"nvim-tree".setup {
      view = {
        signcolumn = "no", -- used to show files diagnostics (FIXME: can these be toggled?)
        preserve_window_proportions = true,
      },
      renderer = {
        add_trailing = true, -- add '/' to folders
        group_empty = true,
        full_name = true, -- for long names, show full name in float win on hover <3
        indent_markers = { enable = true },
        icons = {
          symlink_arrow = "->",
          show = {
            -- disable icons
            -- FIXME: icons on symlinks are still there..
            file = false,
            folder = false,
            git = false,
          }
        },
        -- highlight files by their git status (NvimTreeGit* hl groups)
        highlight_git = true,
      },
      actions = {
        open_file = { resize_window = false },
        -- For actions copy_name, copy_path, copy_absolute_path:
        -- don't put copied text in "+ register (let me manage system clip'), put it in "1 & "" regs
        -- FIXME: need an easy way to transfer "" to "+ on demand ?
        use_system_clipboard = false,
      },
      -- TODO(later): rewrite full mappings to be easier more logical (my own) to use / remember.
    }
  end,
}

NamedPlug.startup_screen {
  source = gh"goolord/alpha-nvim",
  desc = "a lua powered greeter like vim-startify / dashboard-nvim",
  tags = {t.ui, t.extensible},
  depends_on = {NamedPlug.lib_web_devicons},
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
  source = gh"ibhagwan/fzf-lua",
  desc = "Few pre-configured thing selectors (buffers, files, ...)",
  tags = {"nav"},
  depends_on = {NamedPlug.fzf_ctrl},
  on_load = function()
    -- command! FuzzyFilesSmart call fzf#run(fzf#wrap({
    --     \   "source": "fd --type f --type l --follow",
    --     \   "options": ["--multi", "--prompt", "FilesSmart-> "]
    --     \ }))
    -- " Using the default source to find ALL files
    -- command! FuzzyFiles call fzf#run(fzf#wrap({
    --     \   "options": ["--multi", "--prompt", "Files-> "]
    --     \ }))
    -- " TODO: in FuzzyOldFiles, remove files that do not exist anymore (or are not
    -- " really files, like `man://foobar`.
    -- command! FuzzyOldFiles call fzf#run(fzf#wrap({
    --     \   "source": v:oldfiles,
    --     \   "options": ["--multi", "--prompt", "OldFiles-> "]
    --     \ }))
    -- " FIXME: oldfiles are NOT recent files (files recently opened in current
    -- " session are not in v:oldfiles. Need a FuzzyRecentFiles !!
    -- " (same dir? or general? or configurable (in fzf?) ?)
    local act = require"fzf-lua.actions"
    require"fzf-lua".setup{
      winopts = {
        border = "single",
        preview = {
          default = "bat", -- instead of builtin one, using nvim buffers
        },
      },
      fzf_opts = {}, -- don't let them overwrite my own config!
      keymap = {
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
    require"fzf-lua".register_ui_select()

    -- TODO: move to mappings!!
    vim.cmd [[
      nnoremap <silent> <M-f><M-f> <cmd>lua require"fzf-lua".files()<cr>
      nnoremap <silent> <M-f><M-a> <cmd>lua require"fzf-lua".files()<cr>
      nnoremap <silent> <M-f><M-g> <cmd>lua require"fzf-lua".git_files()<cr>
    ]]
  end,
}

Plug {
  source = gh"jremmen/vim-ripgrep",
  desc = "Use RipGrep in Vim and display results in a quickfix list",
  tags = {t.vimscript, "nav"},
}


NamedPlug.fugitive {
  source = gh"tpope/vim-fugitive",
  desc = "A Git wrapper so awesome, it should be illegal",
  tags = {t.vimscript, t.git},
}
Plug {
  source = gh"junegunn/gv.vim",
  depends_on = { NamedPlug.fugitive },
  desc = "Simple (<3) git commit browser, based on vim-fugitive",
  tags = {t.vimscript, t.git},
}
Plug {
  source = gh"whiteinge/diffconflicts",
  -- Use this cmd as mergetool:
  --   nvim -c DiffConflictsWithHistory "$MERGED" "$BASE" "$LOCAL" "$REMOTE"
  desc = "Helper plugin for git merges",
  tags = {t.vimscript, t.git, t.ui},
}

Plug {
  source = gh"rhysd/git-messenger.vim",
  desc = "Popup the commit message of the line under cursor",
  tags = {t.vimscript, t.git, t.ui},
  on_load = function()
    vim.g.git_messenger_no_default_mappings = true
  end,
}

Plug {
  source = gh"lewis6991/gitsigns.nvim",
  desc = "Git integration for buffers",
  tags = {t.code_ui, t.git},
  on_load = function()
    require"gitsigns".setup{
      signs = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "▁" },
        changedelete = { text = "▁" }, -- like delete, but with different highlight
        topdelete    = { text = "▔" },
        untracked    = { text = '┆' },
      },
      attach_to_untracked = true,
      preview_config = { border = "none" },
    }
    vim.api.nvim_set_hl(0, "GitSignsAdd",          { link = "SignVcsAdd" })
    vim.api.nvim_set_hl(0, "GitSignsChange",       { link = "SignVcsChange" })
    vim.api.nvim_set_hl(0, "GitSignsDelete",       { link = "SignVcsDelete" })
    vim.api.nvim_set_hl(0, "GitSignsChangedelete", { link = "SignVcsChange" })
    vim.api.nvim_set_hl(0, "GitSignsTopdelete",    { link = "SignVcsDelete" })
    vim.api.nvim_set_hl(0, "GitSignsUntracked",    { link = "SignVcsUntracked" })

    -- FIXME: use 'on_attach' to config keybinds?

    -- define these globally for now.. (until good solution for per-buffer which_key helper)
    leader_map_define_group{mode={"n"}, prefix_key="h", name="+git-hunks"}
    local gs = require"gitsigns"
    leader_map{mode={"n"}, key="hp", action=gs.preview_hunk, desc="preview hunk"}
    leader_map{mode={"n"}, key="hu", action=gs.reset_hunk,   desc="undo (reset) hunk"}
    leader_map{mode={"n"}, key="hD", action=gs.diffthis,     desc="diff file"}
    -- FIXME: there is no action to toggle fold of everything that didn't change
    -- leader_map{mode={"n"}, key="hf", action=gs.fold_unchanged, desc="fold unchanged lines"}

    -- next/prev hunk that also work in vim's diff mode
    leader_map{mode={"n"}, key="hn", desc="next hunk", opts={expr=true}, action=function()
      if vim.wo.diff then return "]c" end
      vim.schedule(gs.next_hunk) -- need to schedule, cannot run it in an expr mapping
      return "<Ignore>"
    end}
    leader_map{mode={"n"}, key="hN", desc="prev hunk", opts={expr=true}, action=function()
      if vim.wo.diff then return "[c" end
      vim.schedule(gs.prev_hunk) -- need to schedule, cannot run it in an expr mapping
      return "<Ignore>"
    end}

    -- TODO: move closer to git-messenger plugin? Should simply add to a 'git' keymap.
    leader_map{mode={"n"}, key="hb", action="<Plug>(git-messenger)", desc="blame someone"}

    -- toggles
    leader_map_define_group{mode={"n"}, prefix_key="ht", name="+toggle"}
    leader_map{mode={"n"}, key="htw", action=gs.toggle_word_diff,          desc="toggle word diff"}
    leader_map{mode={"n"}, key="htd", action=gs.toggle_deleted,            desc="toggle deleted lines"}
    leader_map{mode={"n"}, key="htb", action=gs.toggle_current_line_blame, desc="toggle blame lens"}

    -- define hunk text object & visual selector
    toplevel_map{mode={"o", "x"}, key="ih", action=gs.select_hunk, desc="select hunk"}
    toplevel_map{mode={"o", "x"}, key="ah", action=gs.select_hunk, desc="select hunk"}
  end,
}
-- FIXME: 'mbbill/undotree' does NOT have diff preview when going up/down :/
-- Best would be 'simnalamburt/vim-mundo' BUT it requires python...
-- See: https://github.com/nvim-lua/wishlist/issues/21
Plug {
  source = gh"mbbill/undotree",
  desc = "Vim undo tree visualizer",
  tags = {t.vimscript, t.ui, t.need_better_plugin},
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
  source = gh"vim-scripts/xterm-color-table.vim",
  desc = "Provide some commands to display all cterm colors",
  tags = {"utils", t.ui, t.vimscript},
}

--------------------------------

NamedPlug.lib_web_devicons {
  source = gh"kyazdani42/nvim-web-devicons",
  desc = "Find (colored) icons for file type",
  tags = {t.ui, t.lib_only},
  on_load = function()
    require'nvim-web-devicons'.set_default_icon("", "#cccccc", 244)
    require'nvim-web-devicons'.setup { default = true } -- give a default icon when nothing matches
  end,
}

NamedPlug.lib_nui {
 source = gh"MunifTanjim/nui.nvim",
 desc = "UI Component Library for Neovim",
 tags = {t.ui, t.lib_only}
}
