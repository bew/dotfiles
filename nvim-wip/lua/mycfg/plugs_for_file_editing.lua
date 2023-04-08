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
      -- Allow fuzzy matching to not match from the beginning
      -- See: https://github.com/hrsh7th/nvim-cmp/issues/1422
      disallow_partial_fuzzy_matching = false,
      -- Fuzzy matching is mostly ok but still broken in some cases (wontfix :/)
      -- See my issue: https://github.com/hrsh7th/nvim-cmp/issues/1443
      -- TODO(?): fork?
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
        -- Mainly used for long words, leveraging fuzzy search!
        -- => Helps with speed & responsiveness :)
        keyword_length = 3,
        option = {
          -- Collect buffer words, following 'iskeyword' option of that buffer
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
      use_treesitter = U.is_module_available("treesitter"),
      show_current_context = U.is_module_available("treesitter"),
    }
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
    -- `{   foo    }` -> `ds{` => `foo`
    -- `{ \n foo \n }` -> `ds{` => `foo`
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

      -- Do not break undo when pairing default rules
      break_undo = false,

      -- map <C-h> to delete a pair if possible
      map_c_h = true,
      -- map <C-w> to delete a pair if possible, like <C-h>
      map_c_w = true,

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
    -- NOTE: Not possible by default, made a PR for it (& changed locally)
    --   https://github.com/windwp/nvim-autopairs/pull/316
    Rule.insert_pair_when = Rule.with_pair
    Rule.cr_expands_pair_when = Rule.with_cr
    Rule.bs_deletes_pair_when = Rule.with_del
    Rule.end_moves_right_when = Rule.with_move
    cond.never = cond.none()
    cond.always = cond.done()
    cond.smart_move_right = cond.move_right
    cond.not_preceded_by_char = cond.not_before_char
    cond.preceded_by_regex = cond.before_regex

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

    -- Properly add 2-spaces or delete 2-spaces when inside brackets
    -- `(|)`   -> press `<space>`     => get: `( | )`
    -- `( | )` -> press `<backspace>` => get: `(|)`
    -- From: https://github.com/windwp/nvim-autopairs/wiki/Custom-rules#alternative-version
    local brackets = { {'(', ')'}, {'[', ']'}, {'{', '}'} }
    npairs.add_rule(
      Rule({start_pair = " ", end_pair = " "})
      :insert_pair_when(function(ctx)
        -- get last char & next char, check if it's a known 'expandable' pair
        local pair = ctx.line:sub(ctx.col -1, ctx.col) -- inclusive indexing
        return vim.tbl_contains({
          brackets[1][1]..brackets[1][2],
          brackets[2][1]..brackets[2][2],
          brackets[3][1]..brackets[3][2],
        }, pair)
      end)
      :end_moves_right_when(cond.never) -- is this the default? (why not?)
      :cr_expands_pair_when(cond.never) -- is this the default? (why not?)
      :bs_deletes_pair_when(function(ctx)
        local col = vim.api.nvim_win_get_cursor(0)[2]
        -- (weird? `col` is one less than what I would have thought..)
        local context = ctx.line:sub(col - 1, col + 2) -- inclusive indexing
        return vim.tbl_contains({
          brackets[1][1]..'  '..brackets[1][2],
          brackets[2][1]..'  '..brackets[2][2],
          brackets[3][1]..'  '..brackets[3][2],
        }, context)
      end)
    )

    -- Pair angle brackets when directly preceded by a word, useful in
    -- languages using angle brackets generics, like Rust (`Foo<T>`)
    -- Taken from https://github.com/windwp/nvim-autopairs/issues/330
    npairs.add_rule(
      Rule({start_pair = "<", end_pair = ">"})
        :insert_pair_when(cond.preceded_by_regex("%a+"))
        :end_moves_right_when(cond.always)
    )

    -- Ensure dquotes are _always_ paired, even when inside quotes
    -- (useful in shell interpolations, or to split a python str in two..)
    -- `x="foo $(bla |) bar"` -> press `"` => `x="foo $(bla "|") bar"`
    -- `" abc | def "`        -> press `"` => `" abc "|" def "`
    -- (use `<M-">` for only one dquote, see below)
    npairs.add_rule(
      Rule({start_pair = [["]], end_pair = [["]]})
        :insert_pair_when(cond.always)
        -- Try to not be smart about dquote insertion, even if in quotes
        -- `|"`
        :end_moves_right_when(cond.never)
        -- normal behavior is:
        -- :end_moves_right_when(cond.smart_move_right())
    )
    -- I: Map `<M-">` to dquote, for when I want only one!
    toplevel_map{mode={"i"}, key=[[<M-">]], action=[["]], desc="insert single dquote"}

    -- Uniformize bquotes handling, for all filetypes!
    -- Makes it work like dquotes, always inserting pair (no smartness)
    -- '|' -> press '`' => '`|`' (normal pairs)
    -- '`|`' -> press '`' => '``|``' (instead of '``|')
    -- Allows to do 3+ bquote blocks without special logic:
    -- '```|```' -> press '`' => '````|````' (instead of weird '````|``````')
    npairs.remove_rule("`")
    npairs.remove_rule("```")
    npairs.add_rule(
      Rule({start_pair = "`", end_pair = "`"})
        :insert_pair_when(cond.always)
        :end_moves_right_when(cond.never) -- ?
    )
    -- I: Map '<M-`>' to bquote, for when I want only one!
    toplevel_map{mode={"i"}, key=[[<M-`>]], action=[[`]], desc="insert single bquote"}
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
      action=[[<ESC><CMD>lua require("Comment.api").locked("comment.linewise")(vim.fn.visualmode())<CR>]],
      desc="force (linewise)",
    }
    leader_map{
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

