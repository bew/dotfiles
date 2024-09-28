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

require"mycfg.diagnostics_and_lsp"

NamedPlug.cmp {
  source = gh"hrsh7th/nvim-cmp",
  desc = "Auto-completion framework",
  -- IDEA: could enable plugins based on roles?
  tags = {t.insert, t.editing, t.careful_update, t.extensible},
  config_depends_on = {
    Plug { source = gh"onsails/lspkind.nvim", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-nvim-lsp", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-buffer", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-path", depends_on = {NamedPlug.cmp} },
    Plug {
      source = gh"hrsh7th/cmp-nvim-lua",
      desc = "Source for neovim runtime API",
      tags = {"config-editing"},
      depends_on = {NamedPlug.cmp},
    },
    Plug { source = gh"andersevenrud/cmp-tmux", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"hrsh7th/cmp-emoji", depends_on = {NamedPlug.cmp} },
    Plug { source = gh"saadparwaiz1/cmp_luasnip", depends_on = {NamedPlug.cmp, NamedPlug.luasnip} },
  },
  on_load = function()
    local cmp = require"cmp"
    -- NOTE: default config is at: https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
    local global_cfg = {}
    global_cfg.preselect = cmp.PreselectMode.None
    global_cfg.snippet = {
      expand = function(args)
        -- TODO: enable when luasnip & LSP configured!
        -- require'luasnip'.lsp_expand(args.body) -- enable soon?
      end
    }
    global_cfg.view = {
      -- NOTE: 'custom' view works best at the moment @2024-02-25
      --   ('native' view has a number of issues with surrounding text editing,
      --   especially snippets from LuaSnip)
      entries = {name = 'custom', selection_order = 'near_cursor' }
    }
    global_cfg.performance = {
      max_view_entries = 15,
    }
    global_cfg.formatting = {}
    global_cfg.window = { completion = {} }

    local protected_formatter = function(custom_fmt_fn)
      return function(entry, original_vim_item)
        local ok, nice_vim_item = pcall(custom_fmt_fn, entry, vim.deepcopy(original_vim_item))
        if not ok then
          original_vim_item.kind = "FAIL" -- indicate something failed during formatting
          return original_vim_item
        end
        return nice_vim_item
      end
    end
    local lspkind = require"lspkind"
    lspkind.init { preset = "codicons" }
    -- WARNING: if this function fails, completion will NOT work
    --   (no completion window will be opened), so we protect it with a wrapper and a default.
    global_cfg.formatting.format = protected_formatter(function(entry, vim_item)
      -- Get symbol for LSP kind
      vim_item.kind = " " .. lspkind.symbolic(vim_item.kind) .. " │"
      return vim_item
    end)

    -- Completion window field ordering & alignment under cursor
    global_cfg.formatting.fields = {"kind", "abbr"}
    -- Tweak completion window to have 'kind' _before_ 'abbr', while keeping 'abbr' right under
    -- current keyword & cursor in-buffer.
    global_cfg.window.completion.col_offset = -4 -- MUST match length of `vim_item.kind` (but as a negative value)
    global_cfg.window.completion.side_padding = 0 -- remove default 1 char padding on the left

    -- NOTE: this should really be in `on_colorscheme_change` hook, but it's better here, close
    -- to formatting code..
    vim.api.nvim_set_hl(0, "CmpItemKind", { ctermfg=33 })
    vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { cterm={bold = true}, ctermfg=202 })
    vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { cterm={bold = true}, ctermfg=202 })
    vim.api.nvim_set_hl(0, "CmpWinBG", { ctermbg=235, ctermfg=252 })
    vim.api.nvim_set_hl(0, "CmpWinSelection", { cterm={bold = true}, ctermbg=238 })
    -- vim.api.nvim_set_hl(0, "CmpWinSelection", { ctermbg=237 })
    global_cfg.window.completion.winhighlight = "Normal:CmpWinBG,CursorLine:CmpWinSelection,Search:None,PmenuSbar:Identifier,PmenuThumb:Keyword"
    -- (!!) Scrollbar HL is not custommizable
    --   cf PR https://github.com/hrsh7th/nvim-cmp/pull/1741
    global_cfg.window.completion.scrollbar = false

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
      -- Allow fuzzy matching to not match from the beginning
      -- See: https://github.com/hrsh7th/nvim-cmp/issues/1422
      disallow_partial_fuzzy_matching = false,
      -- Fuzzy matching is mostly ok but still broken in some cases (wontfix :/)
      -- See my issue: https://github.com/hrsh7th/nvim-cmp/issues/1443
      -- TODO(?): fork?
    }
    local common_sources = {
      { name = 'nvim_lsp' },
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
        -- Mainly used for long words, leveraging fuzzy search (:
        name = "buffer",
        -- I really never need completion of short 2-3 letter words, but it's useful to kick the
        -- auto-completion early to be able to get completion when typing 2-chars with upper or
        -- number chars.
        keyword_length = 2,
        -- Remove simple entries of 3 lowercase chars, since they're simple to write
        entry_filter = function(entry, _ctx)
          local label = entry:get_completion_item().label
          if #label >= 3 then return true end
          -- Remove _simple_ lowercase words (`end` is removed, but `ba3` or `FOo` is kept)
          return label:lower() ~= label
        end,

        option = {
          -- Collect buffer words, following 'iskeyword' option of that buffer
          -- See: https://github.com/hrsh7th/nvim-cmp/issues/453
          keyword_pattern = [[\k\+]],
          -- (Default fn searches words in current buffer only)
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
      { name = "luasnip", keyword_length = 2 },
      { name = "path" }, -- By default, '.' is relative to the buffer
      {
        name = "tmux",
        keyword_length = 4,
        option = {
          capture_history = true,
          all_panes = true,
          trigger_characters = {}, -- all
        },
      },
    }
    local emoji_source = {
      name = "emoji",
      keyword_length = 3,
      trigger_characters = {}, -- don't trigger on ':'
      option = {
        -- insert the emoji char, not the `:txt:`
        insert = true,
      },
    }

    global_cfg.sources = common_sources

    cmp.setup.global(global_cfg)

    -- Filetype/buffer-specific config
    -- NOTE: For these, list of sources does NOT inherit from the global list of sources

    -- Enable neovim runtime API completion only in Lua/Vim files in my nvim config (or plugins):
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = {
        vim.fn.stdpath"config" .. "/*.lua",
        vim.fn.stdpath"config" .. "/*.vim",
        vim.fn.stdpath"state" .. "/*.lua",
        vim.fn.stdpath"state" .. "/*.vim",
        "/*nvim*", -- match any file that mentions `nvim` in its full path
      },
      callback = function()
        cmp.setup.buffer({
          sources = vim.list_extend(
            { { name = "nvim_lua" } },
            common_sources
          )
        })
      end,
    })

    cmp.setup.filetype({"markdown"}, {
      sources = vim.list_extend(
        { emoji_source },
        common_sources
      ),
    })
    cmp.setup.filetype({"gitcommit"}, {
      -- IDEA of source for gitcommit:
      -- 1. for last 100(?) git logs' prefix (like `nvim:`, `cli,nix:`, `zsh: prompt:`, ..)
      --    (only if it's lowercase, to not match ticket numbers like JIRA-456)
      -- 2. for last 100(?) git log summaries (for touched files / for all)
      sources = vim.list_extend(
        {
          {
            name = "buffer",
            keyword_length = 2,
            option = {
              -- (Default fn searches words in current buffer only)
              get_bufnrs = function()
                local bufs = {}
                -- get visible buffers (across all tabs)
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  bufs[vim.api.nvim_win_get_buf(win)] = true
                end
                print("bufs:", vim.inspect(vim.tbl_keys(bufs)))
                return vim.tbl_keys(bufs)
              end,
            }
          },
          emoji_source,
        },
        common_sources
      )
    })
    cmp.setup.filetype({"gitrebase"}, {
      sources = {
        { name = "buffer", keyword_length = 2 }, -- so 'sq'<cmpl.select-next> gives 'squash' directly
      }
    })
  end,
}

NamedPlug.luasnip {
  -- doc: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
  --
  -- Great intro to LuaSnip (~50min):
  -- https://www.youtube.com/watch?v=ub0REXjhpmk
  source = gh"L3MON4D3/LuaSnip",
  desc = "Hyper flexible snippet Engine for Neovim",
  tags = {t.insert, t.editing, t.careful_update, t.extensible},
  rev = "v2.3.0", -- last release @2024-04
  on_load = function()
    local ls = require"luasnip"
    local ls_types = require"luasnip.util.types"
    ls.setup {
      -- Prevent ability to re-enter snippets that have been exited
      history = false,
      -- The events uses to check if we're out of a snippet
      -- Stuff to read around history and jumps
      -- https://github.com/L3MON4D3/LuaSnip/issues/91
      -- https://github.com/L3MON4D3/LuaSnip/issues/170
      -- https://github.com/L3MON4D3/LuaSnip/issues/780
      region_check_events = { "CursorHold" }, -- shortly after (`:h 'updatetime'`)
      -- FIXME: Make snippet expansion buffer-window-local, not buffer-local 👀
      --   When I have 2 windows A & B opened on a buffer (at very different positions),
      --   if I'm in snippet in win A, and I switch to win B to check something at a different part
      --   of the buffer, waiting for region_check_events will exit me from the snippet in win A.
      --
      -- The events used to update the active nodes' dependents (like replicate nodes)
      update_events = {"TextChanged", "TextChangedI"},
      -- The events used to check if a snippet was deleted (to avoid keeping placeholders)
      delete_check_events = {"TextChanged", "InsertLeave"},

      -- FIXME: I don't want to leave the snip when going to prev node when on first placeholder,
      --   or when going next node on the last placeholder.
      --   => I want it to be a no-op
      --
      --   (maybe add Ctrl to be able to 'escape' the snip?)
      --   (quid nested snips? should still work across boundaries
      --   if cursor is not leaving top(/sub?) snippet)

      -- Hint/Highlight some nodes
      ext_opts = {
        [ls_types.snippet] = {
          active = {
            virt_text = { { "<snip>", "Comment" } }
          }
        },
        [ls_types.choiceNode] = {
          active = {
            virt_text = { { "<x/y>", "IncSearch" } }
          }
        },
      },
    }
    -- Auto-(re)load snippets at this path
    require("luasnip.loaders.from_lua").load({
      paths = vim.fn.stdpath"config" .. "/lua/mycfg/snippets_by_ft",
    })

    -- I: Expand snippet if any
    -- IDEA(alternative?): <C-x><C-x> (in insert, maybe also visual?)
    toplevel_map{mode={"i"}, key=[[²]], desc="expand snippet!", action=function()
      ls.expand()
    end}
    toplevel_map{mode={"i", "s"}, key=[[<M-j>]], desc="snippet: jump to next placeholder", action=function()
      -- not checking `ls.in_snippet()`, to be able to jump back to (very) recent snippet(s)
      ls.jump( 1)
    end}
    toplevel_map{mode={"i", "s"}, key=[[<M-k>]], desc="snippet: jump to previous placeholder", action=function()
      -- not checking `ls.in_snippet()`, to be able to jump back to (very) recent snippet(s)
      ls.jump(-1)
    end}
    my_actions.snip_cycle_choice = mk_action_v2 {
      default_desc = "snippet: cycle choice node",
      [{"n", "i", "s"}] = function()
        if ls.in_snippet() and ls.choice_active() then
          ls.change_choice(1)
        end
      end,
    }
    -- FIXME: On wezterm <M-²> sends <M-`> instead
    --   Opened issue at: https://github.com/wez/wezterm/issues/4259
    toplevel_map{mode={"i", "s", "n"}, key=[[<M-²>]], action=my_actions.snip_cycle_choice}
    -- in the mean time use <M-c>
    toplevel_map{mode={"i", "s", "n"}, key=[[<M-c>]], action=my_actions.snip_cycle_choice}

    my_actions.snip_store_visual_selection = mk_action_v2 {
      default_desc = "snippet: store selection for later",
      -- Copied from:
      -- https://github.com/L3MON4D3/LuaSnip/blob/ea7d7ea510c641c4f1504/lua/luasnip/config.lua#L274
      v = [[:lua require('luasnip.util.util').store_selection()<cr>gv"_s]],
      -- TODO: Display a short message like 'LuaSnip: selection stored' (via `vim.notify`?)
      map_opts = {silent = true},
    }
    local_leader_map{mode={"v"}, key=[[²]], action=my_actions.snip_store_visual_selection}
    -- NOTE: do not use direct `²` in visual mode, could be useful for context actions later..

    toplevel_map{mode="s", key=[[<BS>]], action=[[<C-g>"_c]]}
  end,
}

Plug {
  source = gh"lukas-reineke/indent-blankline.nvim",
  desc = "Indent guides",
  tags = {t.code_ui},
  on_load = function()
    require("ibl").setup {
      indent = {
        char = {"¦", "│"},
      },
      scope = {
        char = "┃",
        show_exact_scope = true, -- Don't mark whole lines at start/end of the scope
      },
    }
    -- NOTE: Once scope is setup, see doc for hooks.builtin.scope_highlight_from_extmark to use
    -- the same highlight groups as rainbow-highlights.
    local hooks = require"ibl.hooks"
    -- Replaces the first indentation guide for space/tab indentation with a normal space
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)
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
  -- `Ac` could also take the spaces before it!
  -- Meaning that when I have:
  -- `foobar  -- |some comment`
  -- Doing `dAc` currently does:
  -- `foobar  ` (trailing spaces left!)
  -- I'd like to have:
  -- `foobar`
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
    --   highlights to the modified surrounds? (like with vim-sandwich)

    -- NOTE: Doc on Lua patterns: https://www.lua.org/pil/20.2.html
    --   gotcha: `%s` in patterns includes `\n`!
    local surround_utils = require"nvim-surround.config"
    local my_surrounds = {}
    local my_surrounds_by_ft = {}

    -- Override opening brace&co surrounds: They should represent the braces and
    -- any spaces between them and actual content.
    -- Like this:
    -- `{   foo    }` -> `ds{` => `foo`
    -- `{ \n foo \n }` -> `ds{` => `foo`
    local openers = {
      { open = "(", close = ")" },
      { open = "[", close = "]" },
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
        -- NOTE: the plugin requires `()` after opener/closer pattern-groups to remove it
        delete = U.str_concat(
          "^",
          "(", vim.pesc(opener.open), "%s*)()",
          ".-",
          "(%s*", vim.pesc(opener.close), ")()",
          "$"
        ),
      }
    end

    my_surrounds_by_ft.lua = {}
    -- open/close surrounds for Lua's `[[` & `]]` strings
    my_surrounds_by_ft.lua["<M-[>"] = {
      add = { "[[ ", " ]]" },
      find = vim.pesc"[[" .. ".-" .. vim.pesc"]]",
      delete = U.str_concat(
        "^",
        "(", vim.pesc"[[", "%s*)()",
        ".-",
        "(%s*", vim.pesc"]]", ")()",
        "$"
      )
    }
    my_surrounds_by_ft.lua["<M-]>"] = {
      add = { "[[", "]]" },
      find = vim.pesc"[[" .. ".-" .. vim.pesc"]]",
      delete = U.str_concat(
        "^",
        "(", vim.pesc"[[", ")()",
        ".-",
        "(", vim.pesc"]]", ")()",
        "$"
      )
    }

    -- Disable all default keybinds to use my action system instead
    local disabled_keymaps = {
      normal = false, -- (default: `ys`)
      normal_line = false, -- delims on new lines (default: `yS`)
      normal_cur = false, -- around current line (default: `yss`)
      normal_cur_line = false, -- around current line, delims on new lines (default: `ySS`)
      visual = false, -- around selection (default: `S`)
      visual_line = false, -- around selection, delims on new lines (default: `gS`)
      delete = false, -- delete surround (default: `ds`)
      change = false, -- replace surround (default: `cs`)
      change_line = false, -- replace surround, delims on new lines (default: `cS`)
    }
    my_actions.add_surround = mk_action_v2 {
      default_desc = "Add around <motion>",
      n = "<Plug>(nvim-surround-normal)",
    }
    my_actions.add_surround_on_visual = mk_action_v2 {
      default_desc = "Add around visual selection",
      v = "<Plug>(nvim-surround-visual)",
    }
    my_actions.change_surround = mk_action_v2 {
      default_desc = "Change nearest <from-pair> <to-pair>",
      n = "<Plug>(nvim-surround-change)",
    }
    my_actions.delete_surround = mk_action_v2 {
      default_desc = "Delete nearest <pair>",
      n = "<Plug>(nvim-surround-delete)",
    }
    -- Extra surround actions (on current line, add delims on newlines)
    my_actions.add_surround_on_newline = mk_action_v2 {
      default_desc = "Add around <motion>, delims on newlines",
      n = "<Plug>(nvim-surround-normal-line)",
    }
    my_actions.add_surround_around_line = mk_action_v2 {
      default_desc = "Add around current line",
      n = "<Plug>(nvim-surround-normal-cur)",
    }
    my_actions.add_surround_around_line_on_newline = mk_action_v2 {
      default_desc = "Add around current line, delims on newlines",
      n = "<Plug>(nvim-surround-normal-cur-line)",
    }
    my_actions.add_surround_on_visual_on_newline = mk_action_v2 {
      default_desc = "Add around visual selection, delims on newlines",
      v = "<Plug>(nvim-surround-visual-line)",
    }
    my_actions.change_surround_on_newline = mk_action_v2 {
      default_desc = "Change surrounds, delims on newlines",
      n = "<Plug>(nvim-surround-change-line)",
    }

    -- Map to add surround
    -- (direct `s` would be nice, but eats a key I use too often (I tried...))
    local_leader_map{mode="n", key="s", action=my_actions.add_surround}
    local_leader_map{mode="n", key="S", action=my_actions.add_surround_on_newline}
    local_leader_map{mode="v", key="s", action=my_actions.add_surround_on_visual}
    local_leader_map{mode="v", key="S", action=my_actions.add_surround_on_visual_on_newline}

    -- Maps to change/delete surrounds
    toplevel_map{mode="n", key="cs", action=my_actions.change_surround}
    toplevel_map{mode="n", key="cS", action=my_actions.change_surround_on_newline}
    toplevel_map{mode="n", key="ds", action=my_actions.delete_surround}

    require"nvim-surround".setup {
      keymaps = disabled_keymaps,
      surrounds = my_surrounds,
      move_cursor = "sticky",
    }

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("surround-ft-lua", {}),
      pattern = "lua",
      callback = function()
        require"nvim-surround".buffer_setup {
          surrounds = my_surrounds_by_ft.lua
        }
      end
    })
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
      -- `(|foo`            -> fast_wrap.map -> press `$` => `(|foo)`
      -- `(|)bla (foo) bla` -> fast_wrap.map -> press `$` => `(|bla (foo) bla)`
      -- TODO: See if it's compatible with Luasnip? (w.r.t. extmarks, ..)
      --
      -- IDEA: I think that a more generic plugin to fast-insert a key via hints
      -- would be REALLY handy!
      -- => For example  `<M-,>$` could add a `,` at EOL without moving cursor,
      --    while keeping flexibility, because `$` is _not_ the only hint position!
      --
      -- FIXME<i-action-not-repeatable>
      fast_wrap = {
        map = "<C-M-l>",
        before_key = "i", -- put wrap before targeted position
        after_key = "a", -- put wrap after targeted position

        -- Add '`' char as a potential wrap position
        -- Default pattern: [=[[%'%"%)%>%]%)%}%,]]=]
        -- NOTE: That regex only has a charset, it matches only 1 char
        pattern = U.str_concat(
          "[",
          "%'", [[%"]], "%`",
          "%)", "%>", "%]", "%}",
          "%,",
          "%?",
          "%/",
          "%=",
          "]"
        ),
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

      -- Do not add an undo break when pairing with default rules
      break_undo = false,

      -- Do not disable in macros (didn't see much trouble with having it enabled)
      disable_in_macro = false,

      -- map keys to delete a pair if possible
      map_c_h = true, -- <C-h>
      map_c_w = true, -- <C-w>
      map_bs = true, -- <BS> (backspace)

      -- Don't auto-wrap quoted text
      -- `foo |"bar"` -> press `{` => `foo {|"bar"` (not: `foo {|"bar"}`)
      enable_afterquote = false,
    }

    -- NOTE: The Rule API is a bit weird, and doesn't make the config directly
    --   readable without knowing about how the API works..
    -- See: https://github.com/windwp/nvim-autopairs/wiki/Rules-API
    local Rule = require"nvim-autopairs.rule"
    local cond = require"nvim-autopairs.conds"
    -- Rename some functions to have a more readable config (has many more!)
    Rule.insert_pair_when = Rule.with_pair
    Rule.end_pair_moves_right_when = Rule.with_move
    Rule.cr_expands_pair_when = Rule.with_cr
    Rule.bs_deletes_pair_when = Rule.with_del
    cond.never = cond.none()
    cond.always = cond.done()
    cond.smart_move_right = cond.move_right
    cond.not_preceded_by_char = cond.not_before_char
    cond.preceded_by_regex = cond.before_regex
    cond.not_preceded_by_regex = cond.not_before_regex
    cond.not_followed_by_regex = cond.not_after_regex

    -- FIXME(?): It's not possible to make a SaneRule default without knowing the
    -- internals of Rule:
    -- * Default behavior is 'true' when no condition return either true or false.
    -- * Adding new conditions always adds them at the end of the list
    --   (=> I can't add a fallback behavior at the end)
    --
    -- One nice thing though is that only if the condition function returns nil,
    -- the next condition is checked, so each condition has control
    -- (could completely block / allow the action).

    -- FIXME: I want <bs> at bol to join multiline empty brackets!
    -- text: `(\n|\n)` ; press `<backspace>` ; text: `(|)`

    -- IDEA: `<Tab><Tab>` for `tabout.nvim`-like feature
    --   see: https://github.com/abecodes/tabout.nvim (requires treesitter!)

    -- Properly add 2-spaces or delete 2-spaces when inside brackets
    -- `(|)`   -> press `<space>`     => get: `( | )`
    -- `( | )` -> press `<backspace>` => get: `(|)`
    -- From: https://github.com/windwp/nvim-autopairs/wiki/Custom-rules#alternative-version
    local brackets = { {'(', ')'}, {'[', ']'}, {'{', '}'} }
    npairs.add_rule(
      Rule{start_pair = " ", end_pair = " "}
      :insert_pair_when(function(ctx)
        -- get last char & next char, check if it's a known 'expandable' pair
        local pair = ctx.line:sub(ctx.col -1, ctx.col) -- inclusive indexing
        return vim.tbl_contains({
          brackets[1][1]..brackets[1][2],
          brackets[2][1]..brackets[2][2],
          brackets[3][1]..brackets[3][2],
        }, pair)
      end)
      :end_pair_moves_right_when(cond.never) -- is this the default? (why not?)
      :cr_expands_pair_when(cond.never) -- is this the default? (why not?)
      :bs_deletes_pair_when(function(ctx)
        local col0 = vim.api.nvim_win_get_cursor(0)[2]
        local context = ctx.line:sub(col0 - 1, col0 + 2) -- inclusive indexing
        return vim.tbl_contains({
          brackets[1][1]..'  '..brackets[1][2],
          brackets[2][1]..'  '..brackets[2][2],
          brackets[3][1]..'  '..brackets[3][2],
        }, context)
      end)
    )

    -- Pair angle brackets when directly preceded by a word, optionally with `::`,
    -- useful in languages using angle brackets generics, like Rust (`Foo<T>`, `bla::<T>`)
    -- Taken from comments at <https://github.com/windwp/nvim-autopairs/issues/330>
    npairs.add_rule(
      Rule{start_pair = "<", end_pair = ">"}
        -- NOTE: 2nd param hints the regex to check at least last 3 chars (to work for `foo::|`)
        :insert_pair_when(cond.preceded_by_regex("%a+:?:?$", 3))
        :end_pair_moves_right_when(cond.never)
    )

    -- Uniformize (single/double/back) quotes handling by disabling smart-ness for all filetypes!
    --
    -- `|`   -> press `'` => `'|'`
    -- `'|'` -> press `'` => `''|''` (instead of `''|`)
    --
    -- Allows to do 3+ B-quote blocks without special logic:
    -- '```|```' -> press '`' => '````|````' (instead of weird '````|``````')
    --
    -- Useful in shell interpolations
    -- `x="foo $(bla |) bar"` -> press `"` => `x="foo $(bla "|") bar"`
    --
    -- Useful in a str, to split the str in two strs
    -- `" abc | def "`        -> press `"` => `" abc "|" def "`
    --
    -- (was annoying to repeat the 2nd S-quote in strings.. like `"foo 'bar|"`)
    do
      -- remove builtin quote pairing rules
      npairs.remove_rule([[']])
      npairs.remove_rule([['']]) -- default rule for Nix 👀
      npairs.remove_rule([["]])
      npairs.remove_rule([[`]])
      npairs.remove_rule([[```]])

      npairs.add_rule(
        -- NOTE: Autopairs plugin do not have an override system, need to disable the global pairing
        --   rule for Rust for the Rust-specific rule (wanted override) to work.
        Rule{start_pair = [[']], end_pair = [[']], not_filetypes = {"rust"}}
          -- Always insert second S-quote unless preceded by text (alphanumeric)
          :insert_pair_when(cond.not_preceded_by_regex"%w") -- to write `it's`
          :end_pair_moves_right_when(cond.never)
          -- builtin behavior is normally using cond.smart_move_right()
      )

      npairs.add_rule(
        Rule{start_pair = [["]], end_pair = [["]]}
          :insert_pair_when(cond.always)
          :end_pair_moves_right_when(cond.never)
          -- builtin behavior is normally using cond.smart_move_right()
      )

      npairs.add_rule(
        Rule{start_pair = [[`]], end_pair = [[`]]}
          :insert_pair_when(cond.always)
          :end_pair_moves_right_when(cond.never)
          -- builtin behavior is normally using cond.smart_move_right()
      )

      -- Use <M-THEQUOTE> to get a single quote if needed
      toplevel_map{mode="i", key=[[<M-'>]], action=[[']], desc="insert single S-quote"}
      toplevel_map{mode="i", key=[[<M-">]], action=[["]], desc="insert single D-quote"}
      toplevel_map{mode="i", key=[[<M-`>]], action=[[`]], desc="insert single B-quote"}
    end

    -- [Rust] Override S-quote to avoid pairing when writing fn/type signatures
    -- NOTE: Autopairs plugin do not have an override system, need to disable the global pairing
    --   rule for Rust for this Rust-specific rule to work.
    npairs.add_rule(
      Rule{start_pair = [[']], end_pair = [[']], filetypes = {"rust"}}
        :insert_pair_when(cond.not_preceded_by_regex"%w") -- to write `it's` (same as global rule)
        :insert_pair_when(cond.not_preceded_by_regex"[&<]") -- to write `<'a, Foo>` or `&'a Foo`
        :insert_pair_when(cond.not_followed_by_regex"[>]") -- when going from `<Foo>` to `<Foo, 'a>`
        :end_pair_moves_right_when(cond.never)
    )

    -- Define <C-l> to easily delete the following char (not smart, by design)
    --
    -- Can be useful to delete right-part of a pair if inserted by mistake
    toplevel_map{
      mode="i",
      -- opposite to <C-h>:
      -- <C-h> deletes <-|
      -- <C-l> deletes |->
      key=[[<C-l>]],
      desc="Delete right char (opposite of <BS>)",
      action=[[<Del>]],
    }
  end,
}

Plug {
  source = gh"numToStr/Comment.nvim",
  desc = "Smart and powerful comment plugin for neovim",
  tags = {t.editing, t.textobj},
  on_load = function()
    require("Comment").setup {
      mappings = false,
    }
    -- FIXME: Allow `gcA` to be dot-repeated
    -- Opened issue: https://github.com/numToStr/Comment.nvim/issues/222
    -- (closed as wontfix :/ TODO: make a PR that does it!)

    -- TODO: make omap `ac` also delete leading / trailing spaces for delete action!

    -- NOTE: smart uncomment on inline comments (like `foo /* bar */ baz`) doesn't work automatically by default
    -- => There is a way, when triggering a 'linewise' un/comment/toggle on a region
    --    (via motion / visual selection) that is inside current line, it does an inline block comment
    --    around that region when possible.
    -- Tracking issue: https://github.com/numToStr/Comment.nvim/issues/39

    local_leader_map_define_group{mode={"n", "v"}, prefix_key="cc", name="+comment"}

    local K = {}
    K.esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    my_actions.toggle_line_comment = mk_action_v2 {
      n = {
        default_desc = "toggle comment (linewise)",
        map_opts = {expr = true},
        function()
          if vim.v.count == 0 then
            return "<Plug>(comment_toggle_linewise_current)"
          else
            return "<Plug>(comment_toggle_linewise_count)"
          end
        end,
      },
      v = {
        default_desc = "toggle comment on selection (linewise)",
        function()
          local vmode = vim.fn.visualmode()
          U.feed_keys_sync(K.esc)
          require"Comment.api".locked('toggle.linewise')(vmode)
          U.feed_keys_sync"gv" -- re-select
        end
      },
    }

    -- note: C-/ is remapped to A-/ at terminal-level
    toplevel_map{mode={"n", "v"}, key="<M-/>", action=my_actions.toggle_line_comment}

    local_leader_map{
      mode={"n", "v"},
      key="cc<Space>",
      action=my_actions.toggle_line_comment,
    }
    local_leader_map{
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

    -- These mappings work as a prefix for an operator-pending-like mode
    -- (e.g: '<leader> cct 3j' to toggle comment on 4 lines (linewise))
    -- (e.g: '<leader> cct ip' to toggle comment in-paragraph (linewise))
    -- (e.g: '<leader> cct e' to toggle comment next word (blockwise (it's a little smart!))
    local_leader_map_define_group{mode={"n", "v"}, prefix_key="cct", name="+for-motion"}
    local_leader_map{mode={"n"}, key="cct", action="<Plug>(comment_toggle_linewise)",        desc="toggle for motion (linewise, can inline)"}
    local_leader_map{mode={"v"}, key="cct", action="<Plug>(comment_toggle_linewise_visual)", desc="toggle for motion (linewise, can inline)"}
    --local_leader_map{mode={"n"}, key="ccmb", action="<Plug>(comment_toggle_blockwise)",        desc="toggle for motion (blockwise)"}
    --local_leader_map{mode={"v"}, key="ccmb", action="<Plug>(comment_toggle_blockwise_visual)", desc="toggle for motion (blockwise)"}

    local comment_api = require"Comment.api"
    local_leader_map{mode={"n"}, key="cco", action=comment_api.insert.linewise.below, desc="insert (linewise) below"}
    local_leader_map{mode={"n"}, key="ccO", action=comment_api.insert.linewise.above, desc="insert (linewise) above"}
    local_leader_map{mode={"n"}, key="cca", action=comment_api.insert.linewise.eol,   desc="insert (linewise) at end of line"}

    -- force comment/uncomment line
    -- (normal)
    local_leader_map{mode={"n"}, key="ccc", action=comment_api.call("comment.linewise.current", "g@$"),   desc="force (linewise)", opts={expr = true}}
    local_leader_map{mode={"n"}, key="ccu", action=comment_api.call("uncomment.linewise.current", "g@$"), desc="remove (linewise)", opts={expr = true}}
    -- (visual)
    local_leader_map{
      mode={"v"},
      key="ccc",
      action=[[<ESC><CMD>lua require("Comment.api").locked("comment.linewise")(vim.fn.visualmode())<CR>]],
      desc="force (linewise)",
    }
    local_leader_map{
      mode={"v"},
      key="ccu",
      action=[[<ESC><CMD>lua require("Comment.api").locked("uncomment.linewise")(vim.fn.visualmode())<CR>]],
      desc="remove (linewise)"
    }
  end,
}

Plug {
  source = gh"tommcdo/vim-exchange",
  desc = "Arbitrarily exchange(swap) blocks of code!",
  tags = {t.vimscript, t.editing},
  -- TODO(later): Explicit keybinds, so I can better control which normal keybinds are active.
}

Plug {
  source = gh"johmsalas/text-case.nvim",
  desc = "Plugin for converting text case",
  tags = {t.editing},
  on_load = function()
    local textcase = require"textcase"
    textcase.setup {
      default_keymappings_enabled = false,
    }

    -- ISSUE: cursor off-by-one after case conversion when line doesn't end with a space
    -- with `x foo_bar`, coercing `foo_bar` to anything will move the cursor between `x` and `foo_bar`
    -- with `x foo_bar `, coercing `foo_bar` to anything will move the cursor on `f`
    -- => Cursor pos should end on `f` or (maybe) not move at all.

    -- FIXME: I want an action for interactive change (like for surround),
    --    where I can say `change dot-case to dash-case`
    --
    -- Issues:
    --   With:  `Config.options.triggers`
    --   .. converting to dash-case
    --   Gives: `config-options-triggers` but doesn't keep the case of `Config`..
    --   ---
    --   With:  `ConfigBar.options.triggers`
    --   .. converting to dash-case
    --   Gives: `config-bar-options-triggers` changing all camel and dot-case at the same time..

    -- FIXME: I want to keep cursor position as much as possible!
    --   currently the cursor moves to start-of-converted-word :/

    local key_conversions = {
      { key = "l", fn_id = "to_lower_case", desc = "to lower case" },
      { key = "u", fn_id = "to_upper_case", desc = "to UPPER case" },
      { key = "U", fn_id = "to_constant_case", desc = "TO_CONSTANT_CASE" },
      { key = "c", fn_id = "to_camel_case", desc = "to lowerCamelCase" },
      { key = "C", fn_id = "to_pascal_case", desc = "to PascalCase" },
      { key = "p", fn_id = "to_pascal_case", desc = "to PascalCase" },
      { key = "_", fn_id = "to_snake_case", desc = "to_snake_case" },
      { key = "-", fn_id = "to_dash_case", desc = "to-dash-case (kebab)" },
      { key = "k", fn_id = "to_dash_case", desc = "to-dash-case (kebab)" },
      { key = ".", fn_id = "to_dot_case", desc = "to.dot.case" },
      { key = "/", fn_id = "to_path_case", desc = "to/path/case" },
      { key = "s", fn_id = "to_lower_phrase_case", desc = "to lower sentence" },
      { key = "S", fn_id = "to_upper_phrase_case", desc = "TO UPPER SENTENCE" },
      { key = "t", fn_id = "to_title_case", desc = "To (Title) Sentence" },
    }

    toplevel_map_define_group{mode={"n"}, prefix_key="cr", name="+coerce"}
    toplevel_map_define_group{mode={"n"}, prefix_key="crr", name="+via-lsp-rename"}
    toplevel_map_define_group{mode={"n"}, prefix_key="cro", name="+with-operator"}

    for _, conv in pairs(key_conversions) do
      -- N: cr <action>  => coerce   current word
      toplevel_map{mode={"n"}, key="cr"..conv.key, desc=conv.desc, action=function()
        textcase.current_word(conv.fn_id)
      end}
      -- N: cr r  <action>  => coerce   via lsp_rename
      toplevel_map{mode={"n"}, key="crr"..conv.key, desc=conv.desc, action=function()
        textcase.lsp_rename(conv.fn_id)
      end}
      -- N: cr o  <action>  => coerce   with operator
      toplevel_map{mode={"n"}, key="cro"..conv.key, desc=conv.desc, action=function()
        textcase.operator(conv.fn_id)
      end}
    end

    local_leader_map_define_group{mode={"v"}, prefix_key="cr", name="+coerce"}
    for _, conv in pairs(key_conversions) do
      -- V: <leader> cr <action>     => coerce   visual selection
      local_leader_map{mode={"v"}, key="cr"..conv.key, desc=conv.desc, action=function()
        textcase.operator(conv.fn_id)
      end}
    end
  end,
}
