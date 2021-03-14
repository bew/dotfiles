-- WezTerm configuration
---------------------------------------------------------------

local mytable = require "lib/mystdlib".mytable

-- Misc
------------------------------------------

local cfg_misc = {
  window_close_confirmation = "NeverPrompt",
  check_for_updates = false,

  -- Avoid unexpected config breakage and unusable terminal
  automatically_reload_config = false,

  -- Make sure word selection stops on most punctuations.
  -- Note that dot (.) & slash (/) are allowed though for
  -- easy selection of paths.
  selection_word_boundary = " \t\n{}[]()\"'`,;:",

  hide_tab_bar_if_only_one_tab = true,

  -- Do not hold on exit by default.
  -- Because the default 'CloseOnCleanExit' can be annoying when exiting with
  -- Ctrl-D and the last command exited with non-zero: the shell will exit
  -- with non-zero and the terminal would hang until the window is closed manually.
  exit_behavior = "Close",
}

-- Colors & Appearance
------------------------------------------

local cfg_colors = {
  colors = require("cfg_bew_colors"),
}

-- Font
------------------------------------------

local cfg_fonts = require("cfg_fonts")

-- Key/Mouse bindings
------------------------------------------

-- Key bindings
local cfg_key_bindings = require("cfg_keys")

-- Mouse bindings
local cfg_mouse_bindings = require("cfg_mouse")

-- Merge configs and return!
------------------------------------------

local config = mytable.merge_all(
  cfg_misc,
  cfg_colors,
  cfg_fonts,
  cfg_key_bindings,
  cfg_mouse_bindings,
  {} -- so the last table can have an ending comma for git diffs :)
)

return config
