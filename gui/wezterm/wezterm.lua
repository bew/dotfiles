-- WezTerm configuration
---------------------------------------------------------------

local wezterm = require"wezterm"
local mytable = require "lib/mystdlib".mytable

local cfg_misc = {
  window_close_confirmation = "NeverPrompt",
  check_for_updates = false,

  -- Avoid unexpected config breakage and unusable terminal
  automatically_reload_config = false,

  -- Make sure word selection stops on most punctuations.
  --
  -- Note that dot (.) & slash (/) are allowed though for
  -- easy selection of (partial) paths.
  selection_word_boundary = " \t\n{}[]()\"'`,;:@│┃*…$",

  -- Do not hold on exit by default.
  -- Because the default 'CloseOnCleanExit' can be annoying when exiting with
  -- Ctrl-D and the last command exited with non-zero: the shell will exit
  -- with non-zero and the terminal would hang until the window is closed manually.
  exit_behavior = "Close", -- NOTE: this is now the default, remove?

  -- Disable all noises
  audible_bell = "Disabled",

  hyperlink_rules = mytable.flatten_list {
    wezterm.default_hyperlink_rules(),
    {
      -- Match `gh"owner/repo"` as a github user/repo URL
      -- (this the syntax I use for declaring Neovim plugins in my config)
      regex = [[gh"([\w\d][-\w\d\._]+)/([-\w\d\._]+)"]],
      format = 'https://www.github.com/$1/$2',
    },
    {
      -- Match `uses: owner/repo@rev` as a github user/repo URL at rev/tag
      -- (this the syntax used for using external Github actions)
      regex = [[uses: ([\w\d][^/]+)/([^@]+)@([\w\d\._-]+)]],
      format = 'https://www.github.com/$1/$2/tree/$3',
    },
  }
}

-- Merge configs and return!
------------------------------------------

local full_config = mytable.merge_all(
  cfg_misc,
  require("cfg_appearance"),
  require("cfg_fonts"),
  require("cfg_keys"),
  require("cfg_mouse"),
  {} -- so the last table can have an ending comma for git diffs :)
)

return full_config
