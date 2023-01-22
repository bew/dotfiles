local U = require"mylib.utils"
local _f = U.str_concat
local _s = U.str_surround
local _q = U.str_simple_quote_surround

local KeyRefMustExist_mt = {
  __index = function(self, key)
    error(_f("Unknown key", key))
  end,
}

-----------------------------------------------------------------

local all_plugin_specs = {}
local named_plugin_specs = {}

-- Allows the following syntax:
--   Plug { spec for anonymous plugin }
local function declare_plugin(plugin_spec)
  vim.validate{ plugin_spec={plugin_spec, "table"} }
  -- TODO: validate spec is fully respected!
  table.insert(all_plugin_specs, plugin_spec)
  return plugin_spec
end
local Plug = declare_plugin

local CallToDefinePlugin_mt = {
  __call = function(self, spec_fields)
    if not self.is_placeholder_plugin_spec then
      error(_f("Cannot define the named plugin", _q(self.id), "twice"))
    end
    for k, v in pairs(spec_fields) do
      self[k] = v
    end
    self.is_placeholder_plugin_spec = nil
    declare_plugin(self)
  end,
}

-- THE IDEA:
-- ```
-- NamedPlug.foobar {
--   ...
--   config_depends_on = {
--     -- anonymouse plugin that depends on foobar
--     Plug { ..., depends_on = {NamedPlug.foobar} }
--   },
-- }
-- ```
-- note: 'NamedPlug' is a automagic proxy / setter for 'named_plugin_specs'
local NamedPlug_mt = {
  -- Allows the following syntax:
  --   NamedPlug.foo { spec for plugin named foo }
  -- And save to initial spec, so later references find it.
  __index = function(self, plugin_id)
    if named_plugin_specs[plugin_id] then
      return named_plugin_specs[plugin_id]
    end
    local initial_plugin_spec = setmetatable({
      id = plugin_id,
      is_placeholder_plugin_spec = true, -- will be set to nil when plugin gets defined!
    }, CallToDefinePlugin_mt)
    -- Save named spec, so later references return this spec!
    named_plugin_specs[plugin_id] = initial_plugin_spec
    return initial_plugin_spec
  end,
}
local NamedPlug = setmetatable({}, NamedPlug_mt)

function from_github(owner_repo)
  return setmetatable({
    type = "github",
    owner_repo = owner_repo,
    resolved_name = owner_repo:gsub("^.*/", ""), -- remove 'owner/' in 'owner/repo'
  }, KeyRefMustExist_mt)
end
-- Shorter var for easy/non-bloat use in pkg spec!
local gh = from_github

-- IDEA: attach plugin behavior / load pattern based on tags?
local predefined_tags = setmetatable({}, KeyRefMustExist_mt)
predefined_tags.careful_update = { desc = "Plugins I want to update carefully" }
predefined_tags.vimscript = { desc = "Plugins in vimscript" }
predefined_tags.global_ui = { desc = "Plugins for the global UI" }
predefined_tags.code_ui = { desc = "Plugins for code UI" }
predefined_tags.editing = { desc = "Plugins about code/content editing" }
predefined_tags.git = { desc = "Plugins around git VCS" }
predefined_tags.textobj = { desc = "Plugins to add textobjects" }
predefined_tags.lib_only = { desc = "Plugins that are only useful to other plugins" }
predefined_tags.need_better_plugin = { desc = "Plugins that are 'meh', need to find a better one" }
-- Add name for each tag spec
for k, v in pairs(predefined_tags) do v.name = k end
-- Shorter var for easy/non-bloat use in pkg spec!
local t = predefined_tags

--------------------

NamedPlug.statusline {
  source = gh"rebelot/heirline.nvim",
  desc = "Heirline.nvim is a no-nonsense Neovim Statusline plugin",
  -- Very flexible, modular, declarative, dynamic & nicely customizable !!!
  -- Full doc is available at: https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md
  -- (no vim doc for now)
  tags = {t.global_ui, t.careful_update},
  on_load = function()
    require("mycfg.heirline_statusline_setup").setup()
  end,
}

NamedPlug.cmp {
  source = gh"hrsh7th/nvim-cmp",
  desc = "Auto-completion framework",
  -- IDEA: could enable plugins based on roles?
  tags = {"insert", t.editing, t.careful_update},
  config_depends_on = {
    Plug { source = gh"hrsh7th/cmp-buffer", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-path", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"andersevenrud/cmp-tmux", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-emoji", depends_on = {NamedPlug.cmp} },
  },
  on_load = function()
    local cmp = require"cmp"
    -- NOTE: default config is at: https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
    cmp.setup.global({
      snippet = {
        expand = function(args)
          -- TODO: enable when luasnip configured!
          -- require'luasnip'.lsp_expand(args.body)
        end
      },
      -- TODO? try the configurable popup menu (value: "custom")
      -- view = {
      --   entries = {name = 'custom', selection_order = 'near_cursor' }
      -- }
      view = { entries = "native" }, -- the builtin completion menu
      confirmation = {
        -- disable auto-confirmations!
        get_commit_characters = function() return {} end,
      },
      -- NOTE: mapping presets are in https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/mapping.lua
      mapping = cmp.mapping.preset.insert({
        ["<C-c>"] = cmp.mapping.abort(), -- in addition to <C-e>
        ["<M-C-n>"] = cmp.mapping.scroll_docs(4),
        ["<M-C-p>"] = cmp.mapping.scroll_docs(-4),
      }),
      -- NOTE: default config has lots of sorting functions (cmp.config.compare.*),
      --       and a locality system, try using that first before trying to override it!
      --sorting = {
      --  comparators = {
      --    require'cmp_buffer'.compare_locality, -- sort words by distance to cursor (for buffer & lsp* sources)
      --  }
      --},
      -- NOTE: 'cmp.config.sources' helper allows to specify multiple source arrays.
      -- (internally it generates a single source list, where each source has 'group_index' field set to make groups)
      -- The sources are grouped in the given order, and the groups are displayed as a fallback,
      -- like chain completion.
      sources = cmp.config.sources({
        -- By default, 'buffer' source searches words in current buffer only
        -- TODO: config to search in all opened (or visible?) buffers
        -- IDEA?: make a separate source to search in buffer of same filetype
        --        (its priority should be higher than the 'buffer' source's priority)
        { name = "buffer" },
        { name = "path" }, -- By default, '.' is relative to the buffer
      }, {
        {
          name = "tmux",
          option = { all_panes = true, trigger_characters = {} --[[ all ]], keyword_length = 5 },
        },
      }),
    })
    cmp.setup.filetype({"markdown", "git", "gitcommit"}, {
      -- FIXME: does it replace the global sources? (I hope not)
      sources = {
        {
          name = "emoji",
          option = { insert = true, keyword_length = 4 },
        },
      }
    })
  end,
}

Plug {
  source = gh"folke/which-key.nvim",
  desc = "Display a popup with possible keybindings of the command you started typing",
  tags = {"keys", t.global_ui},
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
    require("which-key").register(wk_leader_n_maps, { mode = "n", prefix = "<leader>" })
    require("which-key").register(wk_leader_v_maps, { mode = "v", prefix = "<leader>" })
    -- TODO: Create a per-buffer map, to avoid crashing WhichKey when the variable
    -- does not exist, we must create a buffer dict, empty for most files,
    -- which will be filled for some file types
    -- FIXME: This does NOT work, because vim-which-key does NOT merge the
    --        dicts of multiple register('same-prefix', different-dict).
    -- autocmd BufRead * let b:which_key_map = {}
    -- autocmd User PluginsLoaded call which_key#register("<space>", "b:which_key_map")
    vim.cmd [[
      augroup my_hi_which_key
        au!
        au ColorScheme * hi WhichKey      ctermfg=33 cterm=bold
        au ColorScheme * hi WhichKeyDesc  ctermfg=172
        au ColorScheme * hi WhichKeyGroup ctermfg=70
      augroup END
    ]]
  end,
}

NamedPlug.fzf_ctrl {
  source = gh"vijaymarupudi/nvim-fzf",
  desc = "A powerful Lua API for using fzf in neovim",
  tags = {"fuzzy"},
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
  tags = {"fuzzy"},
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
  source = gh"kyazdani42/nvim-tree.lua",
  desc = "file explorer tree",
  tags = {t.global_ui, "filesystem"},
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

Plug {
  source = gh"lukas-reineke/indent-blankline.nvim",
  desc = "Indent guides",
  tags = {t.code_ui},
  on_load = function()
    require("indent_blankline").setup {
      char_list = {"¦", "│"},
      show_first_indent_level = false,
      -- show the current indent level on empty lines
      -- (setting it to false would only show the previous indent, not current one)
      show_trailing_blankline_indent = true,
    }
  end,
}

NamedPlug.web_devicons {
  source = gh"kyazdani42/nvim-web-devicons",
  desc = "Find (colored) icons for file type",
  tags = {"ui", t.lib_only},
}

NamedPlug.startup_screen {
  source = gh"goolord/alpha-nvim",
  desc = "a lua powered greeter like vim-startify / dashboard-nvim",
  depends_on = {NamedPlug.web_devicons},
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


NamedPlug.lib_textobj_user {
  source = gh"kana/vim-textobj-user",
  tags = {t.vimscript, t.textobj, t.lib_only},
}

-- textobj: ii ai iI aI
Plug {
  source = gh"kana/vim-textobj-indent",
  desc = "Indent-based text object",
  tags = {t.vimscript, t.textobj},
  depends_on = { NamedPlug.lib_textobj_user },
}

-- textobj: ic ac
Plug {
  source = gh"glts/vim-textobj-comment",
  desc = "Comment text object",
  tags = {t.vimscript, t.textobj},
  depends_on = { NamedPlug.lib_textobj_user },
}

-- textobj: ie ae
--   ae is the entire buffer content
--   ie is like ae without leading/trailing blank lines
Plug {
  source = gh"kana/vim-textobj-entire",
  desc = "Entire-buffer-content text object",
  tags = {t.vimscript, t.textobj},
  depends_on = { NamedPlug.lib_textobj_user },
}

-- textobj: i<Space> a<Space>
--   a<Space> is all whitespace
--   i<Space> is same as a<Space> except it leaves a single space or newline
Plug {
  source = gh"vim-utils/vim-space",
  desc = "Whitespace text object",
  tags = {t.vimscript, t.textobj},
}

Plug {
  source = gh"kylechui/nvim-surround",
  desc = "Add/change/delete surrounding delimiter pairs with ease",
  -- Nice showcases at: https://github.com/kylechui/nvim-surround/discussions/53
  tags = {t.editing, t.extensible},
  on_load = function()
    -- FIXME: is there a way to add subtle add(green)/change(yellow)/delete(red) highlights to the
    -- modified surrounds?
    -- (like with vim-sandwich)
    require"nvim-surround".setup {}
  end,
}

-- FIXME: 'mbbill/undotree' does NOT have diff preview when going up/down :/
-- Best would be 'simnalamburt/vim-mundo' BUT it requires python...
-- See: https://github.com/nvim-lua/wishlist/issues/21
Plug {
  source = gh"mbbill/undotree",
  desc = "Vim undo tree visualizer",
  tags = {t.vimscript, "ui", t.need_better_plugin},
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
  source = gh"tpope/vim-fugitive",
  desc = "A Git wrapper so awesome, it should be illegal",
  tags = {t.vimscript, t.git},
}
Plug {
  source = gh"junegunn/gv.vim",
  desc = "Simple (<3) git commit browser, based on vim-fugitive",
  tags = {t.vimscript, t.git},
}
Plug {
  source = gh"whiteinge/diffconflicts",
  -- Use this cmd as mergetool:
  --   nvim -c DiffConflictsWithHistory "$MERGED" "$BASE" "$LOCAL" "$REMOTE"
  desc = "Helper plugin for git merges",
  tags = {t.vimscript, t.git},
}

Plug {
  source = gh"rhysd/git-messenger.vim",
  desc = "Popup the commit message of the line under cursor",
  tags = {t.vimscript, t.git},
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
        add          = {hl = "SignVcsAdd"   , text = "┃"},
        change       = {hl = "SignVcsChange", text = "┃"},
        delete       = {hl = "SignVcsDelete", text = "▁"},
        changedelete = {hl = "SignVcsChange", text = "▁"}, -- diff is done with different highlight
        topdelete    = {hl = "SignVcsDelete", text = "▔"},
      },
      attach_to_untracked = false,
      preview_config = { border = "none" },

      -- FIXME: use 'on_attach' ? or configure keybinds outside?
      -- (there's no autocmd on attach (yet))
    }

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
  end,
}

Plug {
  source = gh"numToStr/Comment.nvim",
  desc = "Smart and powerful comment plugin for neovim",
  tags = {t.editing, t.textobj},
  on_load = function()
    require('Comment').setup {
      mappings = false,
    }

    -- NOTE: smart uncomment on inline comments (like `foo /* bar */ baz`) doesn't work automatically by default
    -- => There is a way, when triggering a 'linewise' un/comment/toggle on a region
    --    (via motion / visual selection) that is inside current line, it does an inline block comment
    --    around that region when possible.
    -- Tracking issue: https://github.com/numToStr/Comment.nvim/issues/39

    leader_map_define_group{mode={"n", "v"}, prefix_key="cc", name="+comment"}

    leader_map{
      mode={"n"},
      key="cc<Space>",
      action=function()
        if vim.v.count == 0 then
          return "<Plug>(comment_toggle_linewise_current)"
        else
          return "<Plug>(comment_toggle_linewise_count)"
        end
      end,
      desc="toggle current (linewise)",
      opts={expr=true},
    }
    leader_map{
      mode={"n"},
      key="ccb<Space>",
      action=function()
        if vim.v.count == 0 then
          return "<Plug>(comment_toggle_blockwise_current)"
        else
          return "<Plug>(comment_toggle_blockwise_count)"
        end
      end,
      desc="toggle current (blockwise)",
      opts={expr=true},
    }
    leader_map{mode={"v"}, key="cc<Space>", action="<Plug>(comment_toggle_linewise_visual)", desc="toggle selection"}

    -- These mappings work as a prefix for an operator-pending-like mode
    -- (e.g: '<leader> cct 3j' to toggle comment on 4 lines (linewise))
    -- (e.g: '<leader> cct ip' to toggle comment in-paragraph (linewise))
    -- (e.g: '<leader> cct e' to toggle comment next word (blockwise (it's a little smart!))
    leader_map_define_group{mode={"n", "v"}, prefix_key="cct", name="+for-motion"}
    leader_map{mode={"n"}, key="cct", action="<Plug>(comment_toggle_linewise)",        desc="toggle for motion (linewise, can inline)"}
    leader_map{mode={"v"}, key="cct", action="<Plug>(comment_toggle_linewise_visual)", desc="toggle for motion (linewise, can inline)"}
    --leader_map{mode={"n"}, key="ccmb", action="<Plug>(comment_toggle_blockwise)",        desc="toggle for motion (blockwise)"}
    --leader_map{mode={"v"}, key="ccmb", action="<Plug>(comment_toggle_blockwise_visual)", desc="toggle for motion (blockwise)"}

    local comment_api = require"Comment.api"
    leader_map{mode={"n"}, key="cco", action=comment_api.insert.linewise.below, desc="insert (linewise) below"}
    leader_map{mode={"n"}, key="ccO", action=comment_api.insert.linewise.above, desc="insert (linewise) above"}
    leader_map{mode={"n"}, key="cca", action=comment_api.insert.linewise.eol,   desc="insert (linewise) at end of line"}

    -- force comment/uncomment line
    -- (normal)
    leader_map{mode={"n"}, key="ccc", action=comment_api.call("comment.linewise.current", "g@$"),   desc="force (linewise)", opts={expr = true}}
    leader_map{mode={"n"}, key="ccu", action=comment_api.call("uncomment.linewise.current", "g@$"), desc="remove (linewise)", opts={expr = true}}
    -- (visual)
    leader_map{
      mode={"v"},
      key="ccc",
      action="<ESC><CMD>lua require('Comment.api').locked('comment.linewise')(vim.fn.visualmode())<CR>",
      desc="force (linewise)",
    }
    leader_map{
      mode={"v"},
      key="ccu",
      action="<ESC><CMD>lua require('Comment.api').locked('uncomment.linewise')(vim.fn.visualmode())<CR>",
      desc="remove (linewise)"
    }
  end,
}

Plug {
  source = gh"vim-scripts/xterm-color-table.vim",
  desc = "Provide some commands to display all cterm colors",
  tags = {"utils", "ui", t.vimscript},
}

-- Disabled for now, to find all plugins that require it!
--Plug.plenary {
--  source = gh"nvim-lua/plenary.nvim",
--  desc = "Lua contrib stdlib for plugins, used by many plugins",
--  tags = {t.lib_only}
--}

-- NOTE: I don't want all the lazyness and perf stuff of 'lazy'
-- I want a simple plugin loader (using neovim packages), with nice recap UI,
-- update system (?) with lockfile (usable from Nix).
NamedPlug.pkg_manager {
  source = gh"folke/lazy.nvim",
  desc = "A modern plugin manager for Neovim",
  tags = {"boot", t.careful_update},
  on_boot = function()
    local lazy_installed = pcall(require, "lazy")
    if not lazy_installed then return false end

    local lazy_plugin_specs = {}
    for _, plug in pairs(U.filter_list(all_plugin_specs, function(p) return not p.on_boot end)) do
      local lazy_single_spec = { plug.source.owner_repo }
      if plug.on_load then
        --lazy_single_spec.config = plug.on_load
        lazy_single_spec.config = function()
          plug.on_load()
        end
      end
      table.insert(lazy_plugin_specs, lazy_single_spec)
    end
    local plug_names = {}
    for _, plug in pairs(lazy_plugin_specs) do
      table.insert(plug_names, plug[1])
    end
    print("Loading lazy plugins:", vim.inspect(plug_names))
    require("lazy").setup(lazy_plugin_specs, {
      root = "/home/bew/.dot/nvim-wip/pack/lazy-managed-plugins/start",
      install = { missing = false },
      custom_keys = false,
      change_detection = { enabled = false }, -- MAYBE: try it?
      cache = { enabled = false },
      performance = { reset_packpath = false },
      -- Works in the Update UI, but not in the Logs UI
      -- See: https://github.com/folke/lazy.nvim/discussions/353
      --git = { log = {"ORIG_HEAD.."} },
    })
  end,
}

-----------------------------------------------------------------
-- TODO(?): sort all_plugin_specs to have plugins that don't depend on anything first?
-- TODO: Make a list of plugin spec with only those plugins?

local function check_missing_named_plugins(given_plugin_specs)
  for _, plugin_spec in pairs(given_plugin_specs) do
    if plugin_spec.is_placeholder_plugin_spec then
      error(_f("Named plugin", _q(plugin_spec.id), "is not defined!!!"))
    end
  end
end
check_missing_named_plugins(named_plugin_specs)

local function show_plugins_info(given_plugin_specs)
  local plugin_display_name = function(plugin_spec)
    if plugin_spec.id then
      return _f(plugin_spec.source.resolved_name, _s("(id: ", plugin_spec.id, ")"))
    else
      return plugin_spec.source.resolved_name
    end
  end
  for _, plugin_spec in pairs(all_plugin_specs) do
    print("--- Plugin from github:", plugin_display_name(plugin_spec))
    if plugin_spec.depends_on then
      print("Depends on:")
      for _, p in ipairs(plugin_spec.depends_on) do
        print(" -", plugin_display_name(p))
      end
      print(" ")
    end
    if plugin_spec.config_depends_on then
      print("Its config depends on:")
      for _, p in ipairs(plugin_spec.config_depends_on) do
        print(" -", plugin_display_name(p))
      end
      print(" ")
    end
  end
end
--show_plugins_info(all_plugin_specs)

return {
  all_plugin_specs = all_plugin_specs,
  named_plugin_specs = named_plugin_specs,
}
