local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.get_plugin_declarator()

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github

local U = require"mylib.utils"

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
      nested = false, -- don't render nested markdown in code block
      sign = { enabled = false },
      heading = {
        sign = false,
        setext = false, -- disable dashes below text to define headers
        icons = {
          "# ",
          "## ",
          "### ",
          "#4## ",
          "#5### ",
          "#6#### ",
        },
        width = "block",
        right_pad = 2, -- at the very least
        border = {true, true, true, false, false, false},
        above = "▃", -- default: "▄"
        below = "🮃", -- default: "▀"
        foregrounds = { -- for the icon & text
          "@markup.heading.1",
          "@markup.heading.2",
          "@markup.heading.3",
          "@markup.heading.4",
          "@markup.heading.5",
          "@markup.heading.6",
        },
        backgrounds = { -- for the borders + text backgrounds all the way
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
      code = {
        conceal_delimiters = false,
        border = "thin",
        language_border = "▄",
        language_left = "▄█",
        language_right = "█",
        inline_left = "▐",
        inline_right = "▌",
      },
      html = {
        comment = { conceal = false },
      },
      latex = { enabled = false },
      win_options = {
        -- Force disable any concealment in non-rendered mode
        -- REF: https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/303#issuecomment-2608156758
        conceallevel = { default = 0, rendered = 3 },
      },
      overrides = {
        filetype = {
          codecompanion = {
            heading = {
              width = "full",
              custom = {
                me = {
                  pattern = "^## Me$",
                  icon = " ",
                  foreground = "@ai.heading.me",
                  background = "@ai.heading.me",
                },
                cc = {
                  pattern = "^## CodeCompanion.*",
                  icon = " ✨ ",
                  foreground = "@ai.heading.generated",
                  background = "@ai.heading.generated",
                },
              },
            },
          },
        },
      },
    }
  end,
  on_colorscheme_change = function()
    U.hl.set("@ai.heading.me", {
      ctermbg = 94,
      ctermfg = 255,
      bold = true,
    })
    U.hl.set("@ai.heading.generated", {
      ctermbg = 54,
      ctermfg = 220,
      italic = true,
    })
  end,
}

Plug {
  source = gh"mrcjkb/rustaceanvim",
  desc = "🦀 Supercharge your Rust experience in Neovim!",
  tags = {t.ft_support},
  -- note: defer_load not needed, it's already lazy by design
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
