local U = require"mylib.utils"
local _f = U.str_space_concat
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
predefined_tags.ui = { desc = "Plugins for the global UI" }
predefined_tags.code_ui = { desc = "Plugins for code UI" }
predefined_tags.editing = { desc = "Plugins about code/content editing" }
predefined_tags.insert = { desc = "Plugins adding stuff in insert mode" }
predefined_tags.git = { desc = "Plugins around git VCS" }
predefined_tags.textobj = { desc = "Plugins to add textobjects" }
predefined_tags.lib_only = { desc = "Plugins that are only useful to other plugins" }
predefined_tags.extensible = { desc = "Plugins that can be extended" } -- TODO: apply on all relavant!
predefined_tags.need_better_plugin = { desc = "Plugins that are 'meh', need to find a better one" }
-- Add name for each tag spec
for k, v in pairs(predefined_tags) do v.name = k end
-- Shorter var for easy/non-bloat use in pkg spec!
local t = predefined_tags

local function is_module_available(module_name)
  local module_available = pcall(require, module_name)
  return module_available -- bool
end

--------------------

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

NamedPlug.cmp {
  source = gh"hrsh7th/nvim-cmp",
  desc = "Auto-completion framework",
  -- IDEA: could enable plugins based on roles?
  tags = {t.insert, t.editing, t.careful_update, t.extensible},
  config_depends_on = {
    Plug { source = gh"hrsh7th/cmp-buffer", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-path", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"andersevenrud/cmp-tmux", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-emoji", depends_on = {NamedPlug.cmp} },
  },
  on_load = function()
    local cmp = require"cmp"
    -- NOTE: default config is at: https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
    local global_cfg = {}
    global_cfg.snippet = {
      expand = function(args)
        -- TODO: enable when luasnip configured!
        -- require'luasnip'.lsp_expand(args.body)
      end
    }
    -- TODO? try the configurable popup menu (value: "custom")
    -- => Need to set all CmpItem* hl groups!
    --    (they only have gui* styles by default, no cterm*)
    -- global_cfg.view = {
    --   entries = {name = 'custom', selection_order = 'near_cursor' }
    -- }
    global_cfg.view = { entries = "native" } -- the builtin completion menu
    global_cfg.confirmation = {
      -- disable auto-confirmations!
      get_commit_characters = function() return {} end,
    }
    -- NOTE: mapping presets are in https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/mapping.lua
    global_cfg.mapping = cmp.mapping.preset.insert({
      ["<C-c>"] = cmp.mapping.abort(), -- in addition to <C-e>
      ["<M-C-n>"] = cmp.mapping.scroll_docs(4),
      ["<M-C-p>"] = cmp.mapping.scroll_docs(-4),
    })
    -- NOTE: default config has lots of sorting functions (cmp.config.compare.*),
    --       and a locality system, try using that first before trying to override it!
    --sorting = {
    --  comparators = {
    --    require'cmp_buffer'.compare_locality, -- sort words by distance to cursor (for buffer & lsp* sources)
    --  }
    --},
    -- FIXME: writing `thina` still does NOT match `thisisnotaword` :/ why not??
    -- Opened issue: https://github.com/hrsh7th/nvim-cmp/issues/1443
    global_cfg.matching = {
      -- Not sure why this is not the default.. It's not really fuzzy matching otherwise!
      -- See: https://github.com/hrsh7th/nvim-cmp/issues/1422
      disallow_partial_fuzzy_matching = false,
    }
    local common_sources = {
      -- IDEA?: make a separate source to search in buffer of same filetype
      --        (its priority should be higher than the 'buffer' source's priority)
      -- FIXME: There doesn't seem to be a way to change the associated label we see in compl menu
      --        for a given source block..
      --        Only `tmux` source allow configurating the source name in compl menu.
      --        => it should really be a config on source config level, not source definition
      --        level. (or can a single source provide multiple labels???)
      --        NOTE: looking at cmp_tmux's source, it seems to be set per completion item, in
      --        `item.labelDetails.detail`.
      {
        name = "buffer",
        option = {
          -- Collect buffer words, following 'iskeyword' option
          -- See: https://github.com/hrsh7th/nvim-cmp/issues/453
          keyword_pattern = [[\k\+]],
          -- By default, 'buffer' source searches words in current buffer only,
          -- I want instead to look into:
          -- * visible bufs (on all tabs)
          -- * loaded bufs with same filetype
          -- FIXME: Any way to have special compl entry display for visible / same tab / same ft ?
          get_bufnrs = function()
            local bufs = {}
            -- get visible buffers (across all tabs)
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              bufs[vim.api.nvim_win_get_buf(win)] = true
            end
            -- get loaded buffers of same filetype
            local current_ft = vim.api.nvim_buf_get_option(0, "filetype")
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
              local buf_ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
              if is_loaded and buf_ft == current_ft then
                bufs[bufnr] = true
              end
            end
            return vim.tbl_keys(bufs)
          end,
        },
      },
      { name = "path" }, -- By default, '.' is relative to the buffer
      {
        name = "tmux",
        keyword_length = 4,
        option = {
          all_panes = true,
          trigger_characters = {}, -- all
        },
      },
    }

    global_cfg.sources = common_sources

    cmp.setup.global(global_cfg)
    cmp.setup.filetype({"markdown", "git", "gitcommit"}, {
      -- NOTE: This list of sources does NOT inherit from the global list of sources
      sources = vim.list_extend(
        {
          {
            name = "emoji",
            keyword_length = 3,
            option = {
              -- insert the emoji char, not the `:txt:`
              insert = true,
            },
          },
        },
        common_sources
      ),
    })
    -- IDEA of source for gitcommit:
    -- 1. for last 100(?) git logs' prefix (like `nvim:`, `cli,nix:`, `zsh: prompt:`, ..)
    --    (only if it's lowercase, to not match ticket numbers like JIRA-456)
    -- 2. for last 100(?) git log summaries (for touched files / for all)
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
      -- The maximum indent level increase from line to line
      -- => Make sudden big indent not add more indent lines than necessary
      max_indent_increase = 1,

      -- TODO: TEST THIS!
      use_treesitter = is_module_available("treesitter"),
      show_current_context = is_module_available("treesitter"),
    }
  end,
}

Plug {
  source = gh"jremmen/vim-ripgrep",
  desc = "Use RipGrep in Vim and display results in a quickfix list",
  tags = {t.vimscript, "nav"},
}

NamedPlug.web_devicons {
  source = gh"kyazdani42/nvim-web-devicons",
  desc = "Find (colored) icons for file type",
  tags = {t.ui, t.lib_only},
}

NamedPlug.startup_screen {
  source = gh"goolord/alpha-nvim",
  desc = "a lua powered greeter like vim-startify / dashboard-nvim",
  tags = {t.ui, t.extensible},
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
  -- IDEA: when the comment is the last thing of the line,
  -- `ac` could also take the spaces before it!
  -- Meaning that when I have:
  -- `foobar  -- |some comment`
  -- Doing `dac` currently does:
  -- `foobar  ` (trailing spaces left!)
  -- I'd like to have:
  -- `foobar`
  --
  -- BUT I usually don't want it when I do `vac` or `cac`...
  -- Maybe a better solution could be that when `ac` binding is enabled,
  -- add a `dac` binding that implements this behavior?
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
    -- FIXME: is there a way to add subtle add(green)/change(yellow)/delete(red)
    -- highlights to the modified surrounds? (like with vim-sandwich)

    -- NOTE: Doc on Lua patterns: https://www.lua.org/pil/20.2.html
    --   gotcha: `%s` in patterns includes `\n`!
    local surround_utils = require"nvim-surround.config"
    local my_surrounds = {}

    -- Override opening brace&co surrounds: They should represent the braces and
    -- any spaces between them and actual content.
    -- Like this:
    -- `{   foo    }` -> `ds{` -> `foo`
    -- `{ \n foo \n }` -> `ds{` -> `foo`
    local openers = {
      { open = "(", close = ")", open_rx = "%(", close_rx = "%)" },
      { open = "[", close = "]", open_rx = "%[", close_rx = "%]" },
      { open = "{", close = "}" },
    }
    for _, opener in ipairs(openers) do
      my_surrounds[opener.open] = {
        add = { opener.open .. " ", " " .. opener.close },
        find = function()
          return surround_utils.get_selection({ motion = "a" .. opener.open })
        end,
        -- For `(`: "^(%(%s*)().-(%s*%))()$",
        -- For `[`: "^(%[%s*)().-(%s*%])()$",
        -- For `{`: "^({%s*)().-(%s*})()$",
        -- NOTE: the delete pattern will be applied on text returned by `find` above
        -- NOTE: the plugin requires `()` after each opener/closer to remove
        delete = U.str_concat(
          "^",
          "(", (opener.open_rx or opener.open), "%s*)()",
          ".-",
          "(%s*", (opener.close_rx or opener.close), ")()",
          "$"
        ),
      }
    end
    require"nvim-surround".setup {
      surrounds = my_surrounds,
      -- Do not try to re-indent if the change was on a single line
      -- See: https://github.com/kylechui/nvim-surround/issues/201
      indent_lines = function(start_row, end_row)
        if start_row ~= end_row then
          surround_utils.default_opts.indent_lines(start_row, end_row)
        end
      end,
    }
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
  source = gh"windwp/nvim-autopairs",
  desc = "auto insert of second ()''{}[]\"\" etc...",
  tags = {t.editing, t.extensible, t.insert},
  on_load = function()
    -- The plugin is _very_ configurable!
    -- See Rules API at: https://github.com/windwp/nvim-autopairs/wiki/Rules-API
    local npairs = require"nvim-autopairs"
    npairs.setup {
      -- VERY COOL way to interactively close last opened 'pair',
      -- press the map and type one of the hint to place a/the closing pair there!
      -- Workflow:
      -- `(|foo`            -> fast_wrap.map -> press `$` -> `(|foo)`
      -- `(|)bla (foo) bla` -> fast_wrap.map -> press `$` -> `(|bla (foo) bla)`
      -- TODO: See if it's compatible with Luasnip? (w.r.t. extmarks, ..)
      --
      -- IDEA: I think that a more generic plugin to fast-insert a key via hints
      -- would be REALLY handy!
      -- => For example  `<M-,>$` could add a `,` at EOL without moving cursor,
      --    while keeping flexibility, because `$` is _not_ the only hint position!
      fast_wrap = {
        map = "<C-l>",

        -- Add '`' char as a potential wrap position
        -- Default pattern: [=[[%'%"%)%>%]%)%}%,]]=]
        -- NOTE: That regex only has a charset, it matches only 1 char
        pattern = U.str_concat(
          "[",
          "%'", [[%"]], "%`",
          "%)", "%>", "%]", "%}",
          "%,",
          "]"
        ),
        -- FIXME: I can't wrap _before_ a '`', only _after_ :/
        -- Would need a way to target the char before it and give it as a position..
        --
        -- IDEA: Since pattern is a charset that match a single char,
        -- and Lua patterns don't support logical OR, the plugin could receive a
        -- list of lua patterns, and logical OR them!
        -- => Would allow patterns that only match a char if it's preceded by X..
        --    (with a single match group allowed?)
        --
        -- Could be even more powerful with a function that return
        -- (cursor-relative?) positions on the line!
        -- (with a helper function for simple pattern(s) matching)
        -- => Would allow to have positions only at end of tree-sitter nodes..
        -- => Would allow to have positions only in a string if we're in a string..
        -- => Would allow to add some positions only if none matched so far..
      },

      -- Don't auto-wrap quoted text
      -- `foo |"bar"` -> press `{` -> `foo {|"bar"` (not: `foo {|"bar"}`)
      enable_afterquote = false,
    }

    -- NOTE: The Rule API is a bit weird, and and doesn't make the config directly
    --   readable without knowing about how the API works..
    -- See: https://github.com/windwp/nvim-autopairs/wiki/Rules-API
    local Rule = require"nvim-autopairs.rule"
    local cond = require"nvim-autopairs.conds"
    -- Rename some functions to have a more readable config (has many more!)
    -- NOTE: Not possible by default, made a PR for it (& changed locally)
    --   https://github.com/windwp/nvim-autopairs/pull/316
    Rule.insert_pair_when = Rule.with_pair
    Rule.cr_expands_pair_when = Rule.with_cr
    Rule.bs_deletes_pair_when = Rule.with_del
    Rule.just_move_right_when = Rule.with_move
    cond.never = cond.none()
    cond.always = cond.done()

    -- FIXME(?): It's not possible to make a SaneRule default without knowing the
    -- internals of Rule:
    -- * Default behavior is 'true' when no condition return either true or false.
    -- * Adding new conditions always adds them at the end of the list
    --   (=> I can't add a fallback behavior at the end)
    --
    -- One nice thing though is that only if the condition function returns nil,
    -- the next condition is checked, so each condition has control
    -- (could completely block / allow the action).

    -- FIXME: Trying to write this in a shell script:
    -- `some_var="foo $(basename "$to") bar"`
    -- The nested `"` before `$to` was NOT doubled, and trying to write the
    -- second one after writing `$to` doubled it :/
    -- With `|` the cursor:
    -- * From: `some_var="foo $(basename |) bar"`      (Type `"`)
    -- *  Get: `some_var="foo $(basename "|) bar"`     (Type `"`)
    -- *  Get: `some_var="foo $(basename ""|") bar"`
    -- Expected:
    -- * From: `some_var="foo $(basename |) bar"`      (Type `"`)
    -- *  Get: `some_var="foo $(basename "|") bar"`
    --
    -- FIXME: Similar to last FIXME, spliting a quoted string in two isn't easy:
    -- `" abc | def "`     I want: `" abc "|" def "`
    -- But when I input `"`, I get:
    -- `" abc "| def "`
    -- And repeating `"` gives:
    -- `" abc ""|" def "`
    -- Which is not helpful :/
    -- => I think I want `"` to always make a `"|"`
    --    (and I'll bind `<M-">` for when I want a simple `"`)

    -- FIXME: I want <bs> at bol to join multiline empty brackets!
    -- text: `(\n|\n)` ; press `<backspace>` ; text: `(|)`

    -- FIXME: In non-markup lang like in Lua comments, pressing ``` gives ```` (one too much)
    -- It should be considered as a 'triplet' (like in smart-pairs) in _all_ cases.
    -- -> See how it's done for markdown

    -- text: `(|)` ; press `<space>` ; get: `( | )`
    -- text: `( | )` ; press `<backspace>` ; get: `(|)`
    -- From: https://github.com/windwp/nvim-autopairs/wiki/Custom-rules#alternative-version
    local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
    npairs.add_rules {
      (
        Rule({start_pair = " ", end_pair = " "})
          :insert_pair_when(function(ctx)
            -- get last char & next char, check if it's a known 'expandable' pair
            local pair = ctx.line:sub(ctx.col -1, ctx.col)
            return vim.tbl_contains({
              brackets[1][1]..brackets[1][2],
              brackets[2][1]..brackets[2][2],
              brackets[3][1]..brackets[3][2]
            }, pair)
          end)
          :just_move_right_when(cond.never) -- is this the default? (why not?)
          :cr_expands_pair_when(cond.never) -- is this the default? (why not?)
          :bs_deletes_pair_when(function(ctx)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = ctx.line:sub(col - 1, col + 2)
            return vim.tbl_contains({
              brackets[1][1]..'  '..brackets[1][2],
              brackets[2][1]..'  '..brackets[2][2],
              brackets[3][1]..'  '..brackets[3][2]
            }, context)
          end)
      ),
    }
  end,
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
  source = gh"rhysd/committia.vim",
  desc = "More pleasant editing on commit messages with dedicated msg/status/diff windows",
  tags = {t.vimscript, t.git},
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

Plug {
  source = gh"numToStr/Comment.nvim",
  desc = "Smart and powerful comment plugin for neovim",
  tags = {t.editing, t.textobj},
  on_load = function()
    require('Comment').setup {
      mappings = false,
    }
    -- FIXME: Allow `gcA` to be dot-repeated
    -- Opened issue: https://github.com/numToStr/Comment.nvim/issues/222
    -- (closed as wontfix :/ TODO: make a PR that does it!)

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
  source = gh"tommcdo/vim-exchange",
  desc = "Arbitrarily exchange(swap) blocks of code!",
  tags = {t.vimscript},
  -- TODO(later): Explicit keybinds, so I can better control which normal keybinds are active.
}

Plug {
  source = gh"vim-scripts/xterm-color-table.vim",
  desc = "Provide some commands to display all cterm colors",
  tags = {"utils", t.ui, t.vimscript},
}

Plug {
  source = gh"ethanholz/nvim-lastplace",
  desc = "Intelligently reopen files at your last edit position",
  -- It handles more edge cases (and is actually configurable) than the autocmd that
  -- is documented at `:h restore-cursor`.
  tags = {"utils"},
  on_load = function()
    require'nvim-lastplace'.setup {
      lastplace_ignore_buftype = {"quickfix", "nofile", "help"},
      lastplace_ignore_filetype = {"gitcommit", "gitrebase"},
      lastplace_open_folds = true,
    }
  end,
}

-- Disabled for now, to find all plugins that require it!
--Plug.plenary {
--  source = gh"nvim-lua/plenary.nvim",
--  desc = "Lua contrib stdlib for plugins, used by many plugins",
--  tags = {t.lib_only}
--}

-- NOTE: I don't want all the lazyness and perf stuff of 'lazy'
-- I want a simple plugin loader (using neovim packages), with nice recap UI,
-- interactive update system, with a lockfile (usable from Nix).
--
-- I want a way to ask what plugins has updates, see git log, and update plugins individually on
-- demand (or by tags inclusion/exclusion).
-- => It's actually already possible (except filtering on tags) with `Lazy check` then `Lazy logs`
--
-- TODO: Ask a way to disable the 'update' tab, which is potentially too dangerous,
-- I want to review plugins updates before I actuall update them!
NamedPlug.pkg_manager {
  source = gh"folke/lazy.nvim",
  desc = "A modern plugin manager for Neovim",
  tags = {"boot", t.careful_update},
  on_boot = function()
    if not is_module_available("lazy") then return false end

    local lazy_plugin_specs = {}
    for _, plug in pairs(U.filter_list(all_plugin_specs, function(p) return not p.on_boot end)) do
      local lazy_single_spec = { plug.source.owner_repo }
      lazy_single_spec.init = plug.on_pre_load
      lazy_single_spec.config = plug.on_load
      table.insert(lazy_plugin_specs, lazy_single_spec)
    end
    local plug_names = {}
    for _, plug in pairs(lazy_plugin_specs) do
      table.insert(plug_names, plug[1])
    end
    --print("Loading lazy plugins:", vim.inspect(plug_names))
    require("lazy").setup(lazy_plugin_specs, {
      root = "/home/bew/.dot/nvim-wip/pack/lazy-managed-plugins/start",
      install = { missing = false },
      custom_keys = false,
      change_detection = { enabled = false }, -- MAYBE: try it?
      cache = { enabled = false },
      performance = { reset_packpath = false },
      git = {
        -- In the Logs UI, show commits that are 'pending'
        -- (for plugins not yet updated to their latest fetched commit)
        -- => Will show nothing for plugins that are up-to-date, but I can always go
        --    where the plugin is (can copy path from plugin details) and `git log`!
        log = {"..origin/HEAD"}
      },
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
