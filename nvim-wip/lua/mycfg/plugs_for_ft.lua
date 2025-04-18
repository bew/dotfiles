local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.PlugDeclarator

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github

--------------------------------

Plug {
  source = gh"rhysd/committia.vim",
  desc = "More pleasant editing on commit messages with dedicated msg/status/diff windows",
  tags = {t.vimscript, t.git, t.ft_support},
  -- Can't use defer_load, otherwise it doesn't appear when opening a commit msg buffer :/
}

Plug {
  source = gh"MeanderingProgrammer/render-markdown.nvim",
  desc = "Plugin to improve viewing Markdown files in Neovim",
  tags = {t.ft_support, t.content_ui},
  defer_load = {
    on_event = "VeryLazy",
    on_ft = { "markdown", "codecompanion" },
  },
  depends_on = {
    Plug.ts,
    Plug.lib_web_devicons,
  },
  on_load = function()
    require"render-markdown".setup {
      -- Don't disable all rendering (prevent layout disruption) when selecting un-related text
      render_modes = { "n", "v", "V", "c", "t" }, -- adds visual modes compared to defaults
      sign = { enabled = false },
      heading = {
        sign = false,
        position = "inline",
        icons = {
          "# 󰎤  ",
          "## 󰎩  ",
          "### 󰎪  ",
          "#### 󰎮  ",
          "##### 󰎱  ",
          "###### 󰎵  ",
        },
        width = "block",
        min_width = { 90, 70, 60, 50, 50, 50 },
        right_pad = 2, -- at the very least
        border = {true, true, true, false, false, false},
        above = "▄", -- default: "▄"
        below = "▀", -- default: "▀"
        foregrounds = {
          "@markup.heading.1",
          "@markup.heading.2",
          "@markup.heading.3",
          "@markup.heading.4",
          "@markup.heading.5",
          "@markup.heading.6",
        },
        backgrounds = { -- for the borders + backgrounds all the way
          "@markup.heading.1.bg",
          "@markup.heading.2.bg",
          "@markup.heading.3.bg",
          "@markup.heading.4.bg",
          "@markup.heading.5.bg",
          "@markup.heading.6.bg",
        },
      },
      dash = {
        icon = "━",
        width = 80,
        highlight = "@punctuation.delimiter.markdown",
      },
      bullet = { enabled = false },
      html = {
        comment = { conceal = false },
      },
      latex = { enabled = false },
      win_options = {
        -- Force disable any concealment in non-rendered mode
        -- REF: https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/303#issuecomment-2608156758
        conceallevel = { default = 0, rendered = 3 },
      },
    }
  end,
}

Plug {
  source = gh"preservim/vim-markdown",
  desc = "Markdown Vim Mode",
  tags = {t.vimscript, t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "markdown" },
  on_pre_load = function()
    vim.g.vim_markdown_folding_disabled = true
    vim.g.vim_markdown_conceal = false
    vim.g.vim_markdown_conceal_code_blocks = false
    vim.g.vim_markdown_frontmatter = true
    vim.g.vim_markdown_new_list_item_indent = 2

    -- Recognize additional fenced language shortcuts
    -- (in addition to all filetypes)
    vim.g.vim_markdown_fenced_languages = {
      "hcl=terraform",
      "py=python",
      "shell=sh",
      "ini=dosini",
    }

    vim.g.vim_markdown_auto_insert_bullets = 0 -- Because I don't want <Enter> to make a new bullet!
    -- Note: auto bullet works by setting '*', '+', '-' as a comment leader, and configuring vim to
    -- auto insert comment leader on <Enter> (with 'formatoptions').
    -- TODO: Ideally I want <Enter> to make a new line in the same bullet, and <o> to make a new bullet.
    --   The problem is that I also want <Enter> in a quote to auto-add '>' (also set as a comment
    --   leader) and <o> to make a new line _without_ the quote char '>'.
    --   So the *exact* opposite of the bullet behavior.
    --   I don't think it's possible to configure vim to have multiple <Enter>/<o> behavior based
    --   on the comment leader ('-' vs '>').
    --   => Would need to configure that behavior myself..
    -- FIXME need to investigate: For some reason, auto-insert and indents of numbered lists
    --   DO NOT WORK with this plugin. (vim options: 'formatoptions' flag 'n', and 'formatlistpat')
  end,
  on_colorscheme_change = function()
    -- This group is used for spaces-only lines in markdown files.
    -- Linking it to 'Normal' is the way to reset it, without having it using its default link
    -- (which is 'Visual').
    -- Ref: https://app.element.io/#/room/#neovim:matrix.org/$On00YaHqUrbIocahX-RpkZcqbDh-Kw6Cfn6TTs0t5As
    vim.cmd[[ hi link mkdLineBreak Normal ]]

    vim.cmd[[ hi markdownCode ctermfg=29 ]]

    -- In Markdown doc, make italic & bold standout from normal text, using colors in
    -- addition to cterm's italic/bold for terminals without support for bold/italic.
    --
    -- In plasticboy/vim-markdown, italic/bold highlights seems to come from HTML
    -- syntax groups, which is wrong.  I want to configure highlights for
    -- markdown only, not html!
    --
    -- Tracking issue: https://github.com/plasticboy/vim-markdown/issues/521
    --
    -- In the meantime, we need to set both html & mkd groups:
    -- * mkd groups are used for the delimiters
    vim.cmd[[ hi mkdItalic ctermfg=243 ctermbg=235 ]]
    vim.cmd[[ hi mkdBold ctermfg=243 ctermbg=235 ]]
    -- * html groups are used for the content
    vim.cmd[[ hi htmlItalic cterm=italic ctermfg=251 ctermbg=235 ]]
    vim.cmd[[ hi htmlBold cterm=bold ctermfg=255 ctermbg=235 ]]

    -- Give a basic progression/difference between H1, H2, H3.. titles
    vim.cmd[[ hi htmlH1 cterm=bold ctermfg=255 ctermbg=130 ]]
    vim.cmd[[ hi htmlH2 cterm=bold ctermfg=232 ctermbg=252 ]]
    vim.cmd[[ hi! link htmlH3 Title ]]
    -- NOTE: htmlH4 is linked to htmlH3, htmlH5 is linked to htmlH4, ..
  end,
}

Plug.lazydev_lua {
  source = gh"folke/lazydev.nvim",
  desc = "Faster LuaLS setup for Lua & Neovim-specific files",
  tags = {t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "lua" },
  config_depends_on = {
    Plug { source = gh"Bilal2453/luvit-meta", defer_load = { on_event = "VeryLazy", on_ft = "lua" } },
  },
  on_load = function()
    require"lazydev".setup {
      library = {
        -- Only load luvit types when the `vim.uv` or `vim.loop` word is found
        { path = "luvit-meta/library", words = { "vim%.uv", "vim%.loop" } },
      }
    }
  end,
}

Plug {
  source = gh"mrcjkb/rustaceanvim",
  desc = "🦀 Supercharge your Rust experience in Neovim!",
  tags = {t.ft_support},
  -- defer_load not needed, it's already lazy by design
}

Plug {
  source = gh"NoahTheDuke/vim-just",
  desc = "Just's justfile support",
  tags = {t.vimscript, t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "just" },
}

Plug {
  source = gh"LnL7/vim-nix",
  desc = "Nix files support",
  tags = {t.vimscript, t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "nix" },
}

Plug {
  source = gh"kaarmu/typst.vim",
  desc = "Vim plugin for Typst language",
  tags = {t.vimscript, t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "typst" },
}

Plug {
  source = gh"elkasztano/nushell-syntax-vim",
  desc = "nushell files support",
  tags = {t.vimscript, t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "nu" },
}

Plug {
  source = gh"hashivim/vim-terraform",
  desc = "basic vim/terraform integration",
  tags = {t.vimscript, t.ft_support},
  defer_load = { on_event = "VeryLazy", on_ft = "terraform" },
}
