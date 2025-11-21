local U = require"mylib.utils"

local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
-- local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.insert, t.editing },
}

--------------------------------

---@param plug_spec plugsys.PluginSpec
local function cmp_source_dep(plug_spec)
  local spec = vim.tbl_extend("error", plug_spec, {
    ---@diagnostic disable-next-line: undefined-field (`extra_depends_on` is an extra!)
    depends_on = U.concat_lists({ Plug.cmp }, plug_spec.extra_depends_on),
    defer_load = { on_event = "VeryLazy" }, -- 🤔 (like cmp)
  })
  return Plug(spec)
end
Plug.cmp {
  source = gh"hrsh7th/nvim-cmp",
  desc = "Auto-completion framework",
  -- IDEA: could enable plugins based on buffer roles?
  tags = {t.careful_update},
  config_depends_on = {
    Plug { source = gh"onsails/lspkind.nvim", defer_load = { autodetect = true } },
    cmp_source_dep { source = gh"hrsh7th/cmp-nvim-lsp" },
    cmp_source_dep { source = gh"hrsh7th/cmp-buffer" },
    cmp_source_dep { source = gh"hrsh7th/cmp-path" },
    Plug.lazydev_lua,
    cmp_source_dep { source = gh"andersevenrud/cmp-tmux" },
    cmp_source_dep { source = gh"hrsh7th/cmp-emoji" },
    cmp_source_dep { source = gh"saadparwaiz1/cmp_luasnip", extra_depends_on = {Plug.luasnip} },
    -- Treesitter source isn't super useful for words, but it's really nice in some cases for string
    -- literals, comments and some other nodes.
    cmp_source_dep {
      source = gh"bew/cmp-treesitter", -- my fork! 🚀
      version = { branch = "bew-appropriation" },
    },
  },
  defer_load = { on_event = "VeryLazy" }, -- 🤔 (seems to work 🤷)
  on_load = function()
    local cmp = require"cmp"
    -- NOTE: default config is at: https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
    local global_cfg = {}
    global_cfg.preselect = cmp.PreselectMode.None
    global_cfg.snippet = {
      expand = function(args)
        require"luasnip".lsp_expand(args.body)
      end
    }
    global_cfg.view = {
      -- NOTE: 'custom' view works best at the moment @2024-02-25
      --   ('native' view has a number of issues with surrounding text editing,
      --   especially snippets from LuaSnip)
      entries = {name = "custom", selection_order = "near_cursor" }
    }
    global_cfg.formatting = {}
    global_cfg.window = {
      documentation = {},
      completion = {
        scrolloff = 2,
        max_height = 15,
      },
    }

    local protected_formatter = function(custom_fmt_fn)
      return function(entry, original_vim_item)
        local ok, nice_vim_item = pcall(custom_fmt_fn, entry, vim.deepcopy(original_vim_item))
        if not ok then
          original_vim_item.kind = "FMTFAIL" -- indicate something failed during formatting
          -- print(vim.inspect(nice_vim_item --[[ the error ]]))
          return original_vim_item
        end
        return nice_vim_item
      end
    end
    local lspkind = require"lspkind"
    lspkind.init { preset = "codicons" }
    local SRC_TO_MENU_TAG = {
      buffer   = "@Buf+",
      emoji    = "@Emo ",
      luasnip  = "@Snip",
      nvim_lsp = "@Lsp ",
      lazydev  = "@LLua",
      path     = "@Path",
      tmux     = "@Tmux",
      treesitter = "@TS",
    }
    -- WARNING: if this function fails, completion will NOT work
    --   (no completion window will be opened), so we protect it with a wrapper and a default.
    global_cfg.formatting.format = protected_formatter(function(entry, vim_item)
      -- Get symbol for LSP kind
      local lsp_symbol = lspkind.symbolic(vim_item.kind)
      if #lsp_symbol == 0 then
        -- NOTE: happens when kind is not an LSP kind
        -- (e.g. treesitter source puts the highlight capture name)
        lsp_symbol = "?"
      end
      vim_item.kind = " " .. lsp_symbol .. " │"

      -- Entry source name
      local src_name = entry.source.name
      local src_label
      if SRC_TO_MENU_TAG[src_name] then
        src_label = SRC_TO_MENU_TAG[src_name]
      else
        src_label = src_name:sub(1, 5)
      end

      -- Limit width of completion window
      -- Inspired from: <https://github.com/hrsh7th/nvim-cmp/discussions/609#discussioncomment-5727678>
      do
        local MAX_LABEL_WIDTH = 47
        local MIN_LABEL_WIDTH = 10
        local label = vim_item.abbr
        if #label > MAX_LABEL_WIDTH then
          vim_item.abbr = vim.fn.strcharpart(label, 0, MAX_LABEL_WIDTH - 1) .. "…"
        elseif #label < MIN_LABEL_WIDTH then
          vim_item.abbr = label .. (" "):rep(MIN_LABEL_WIDTH - #label)
        end

        local MAX_INFO_WIDTH = 40
        local info = vim_item.menu or "" -- (nil for simple sources)
        if #info > MAX_INFO_WIDTH then
          info = vim.fn.strcharpart(info, 0, MAX_INFO_WIDTH - 1) .. "…"
        end

        -- note: We put the src_label before, so they're all aligned vertically
        if #info > 0 then
          info = "║ " .. info
        end
        vim_item.menu = " " .. src_label .. info
      end

      return vim_item
    end)

    -- Completion window field ordering & alignment under cursor
    global_cfg.formatting.fields = {"kind", "abbr", "menu"}
    -- Tweak completion window to have 'kind' _before_ 'abbr', while keeping 'abbr' right under
    -- current keyword & cursor in-buffer.
    global_cfg.window.completion.col_offset = -4 -- MUST match length of `vim_item.kind` (but with a negative value)
    global_cfg.window.completion.side_padding = 0 -- remove default 1 char padding on the left

    -- NOTE: see highlight groups defined below
    global_cfg.window.completion.winhighlight = "Normal:CmpWinBG,CursorLine:CmpWinSelection,Search:None,PmenuSbar:Identifier,PmenuThumb:Keyword"
    -- (!!) Scrollbar HL is not custommizable
    --   cf PR https://github.com/hrsh7th/nvim-cmp/pull/1741
    global_cfg.window.completion.scrollbar = false
    global_cfg.window.documentation.scrollbar = false

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
    global_cfg.matching = {
      -- Allow fuzzy matching to not match from the beginning
      -- See: https://github.com/hrsh7th/nvim-cmp/issues/1422
      disallow_partial_fuzzy_matching = false,
      -- Fuzzy matching is mostly ok but still broken in some cases (wontfix :/)
      -- See my issue: https://github.com/hrsh7th/nvim-cmp/issues/1443
      -- TODO(?): fork? Or switch to blink.cmp 👀
    }

    -- warn: Source WITHOUT a priority seems to get a big buf
    local prio = { high = 150, med = 100, low = 50 }
    local common_sources = {
      { name = "nvim_lsp", priority = prio.high },
      {
        name = "luasnip",
        priority = prio.high,
        keyword_length = 2,
      },
      -- IDEA?: make a separate source to search in buffer of same filetype
      --        (its priority should be higher than the 'buffer' source's priority)
      {
        -- Mainly used for long words, leveraging fuzzy search (:
        name = "buffer",
        priority = prio.med,
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
            local current_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
              local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
              if is_loaded and buf_ft == current_ft then
                bufs[bufnr] = true
              end
            end
            return vim.tbl_keys(bufs)
          end,
        },
      },
      { name = "path", priority = prio.med }, -- note: By default, '.' is relative to the buffer
      {
        -- FIXME: Had a weird case with a TS match bad prefix/grouping compared to an LSP match,
        -- but for some reason that TS match was MORE prioritzed than the LSP with was lodged in
        -- middle 👀
        --
        -- Example:
        -- With `Err(anho|)` input (`|` is the cursor)
        -- I got this completion list (without `priority` setting):
        --    │ Err(anyhow!("{directive_n… (P)  @TS
        --    │ anyhow!                         @Lsp
        --
        -- BUG:
        -- I want to get to `anyhow!` but when I navigate to the first one (to got through it) the
        -- completion menu closes immediately for some reason and I can't simply undo that wrong
        -- inserted text ><
        -- 👉 Seems to happen when a match (label? text?) has `{` or `}` 🤔
        --   .. TODO: minimal repro!
        name = "treesitter",
        priority = prio.low, -- it can easily match too much..
        keyword_length = 4, -- Has lots of noise at 1 char (default)
        -- FIXME: do NOT consider current word as a potentiol match 👀
        -- (iirc it shouldn't but it still does sometimes..)
      },
      {
        name = "tmux",
        priority = prio.low,
        keyword_length = 4,
        option = {
          label = "", -- remove label in 'menu', I put mine already
          capture_history = true,
          all_panes = true,
          trigger_characters = {}, -- all
        },
      },
    }
    local emoji_source = {
      name = "emoji",
      priority = prio.med,
      keyword_length = 3,
      trigger_characters = {}, -- don't trigger on ':', but only after chars prefixed by `:`
      option = {
        -- insert the emoji char, not the `:txt:`
        insert = true,
      },
    }

    global_cfg.sources = common_sources

    cmp.setup.global(global_cfg)

    -- Filetype/buffer-specific config
    -- NOTE: For these, list of sources does NOT inherit from the global list of sources

    cmp.setup.filetype({"lua"}, {
      sources = vim.list_extend(
        { { name = "lazydev", priority = prio.high } },
        common_sources
      ),
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
            priority = prio.med,
            keyword_length = 2,
            option = {
              -- (Default fn searches words in current buffer only)
              get_bufnrs = function()
                local bufs = {}
                -- get visible buffers (across all tabs)
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  bufs[vim.api.nvim_win_get_buf(win)] = true
                end
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
  on_colorscheme_change = function()
    local cols = {}
    cols.CmpItemKind = { ctermfg=33 } -- TODO: add more specialized Kind colors
    cols.CmpItemKindText = { ctermfg=242 }
    cols.CmpItemKindFolder = { ctermfg=33 }
    cols.CmpItemKindFile = { ctermfg=250 }
    --
    cols.CmpItemMenu = { ctermfg=244, italic = true }
    cols.CmpItemAbbrDeprecated = { ctermfg=244, strikethrough = true }
    cols.CmpItemAbbrMatch = { ctermfg=202, bold = true }
    cols.CmpItemAbbrMatchFuzzy = { ctermfg=202, bold = true }
    --
    cols.CmpWinBG = { ctermbg=235, ctermfg=252 }
    cols.CmpWinSelection = { ctermbg=238, bold = true }
    for hlgroup, hlspec in pairs(cols) do
      U.hl.set(hlgroup, hlspec)
    end
  end,
}
