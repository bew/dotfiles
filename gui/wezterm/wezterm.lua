-- WezTerm configuration
---------------------------------------------------------------

local cfg_misc = {
  window_close_confirmation = "NeverPrompt",
  check_for_updates = false,

  -- Avoid unexpected config breakage and unusable terminal
  automatically_reload_config = false,

  -- Make sure word selection stops on most punctuations.
  -- Note that dot (.) & slash (/) are allowed though for
  -- easy selection of paths.
  selection_word_boundary = " \t\n{}[]()\"'`,;:@│",

  hide_tab_bar_if_only_one_tab = true,

  -- Do not hold on exit by default.
  -- Because the default 'CloseOnCleanExit' can be annoying when exiting with
  -- Ctrl-D and the last command exited with non-zero: the shell will exit
  -- with non-zero and the terminal would hang until the window is closed manually.
  exit_behavior = "Close",

  -- Pad window to avoid the content to be too close to the border,
  -- so it's easier to see and select.
  window_padding = {
    left = 3, right = 3,
    top = 3, bottom = 3,
  },
}

-- Merge configs and return!
------------------------------------------

local mytable = require "lib/mystdlib".mytable
local full_config = mytable.merge_all(
  cfg_misc,
  {colors = require("cfg_bew_colors")},
  require("cfg_fonts"),
  require("cfg_keys"),
  require("cfg_mouse"),
  {} -- so the last table can have an ending comma for git diffs :)
)

return full_config
