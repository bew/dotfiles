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
  selection_word_boundary = " \t\n{}[]()\"'`,;:@",

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

  -- cf the original issue (mine): https://github.com/wez/wezterm/issues/478 solved for me but not for everyone..
  -- cf the addition of this flag: https://github.com/wez/wezterm/commit/336f209ede27dd801f989419155e475f677e8244
  -- OK BUT NO, disabled because it does some weird visual artifacts:
  --  * About cursor behaviors:
  --    When a ligature is a the end of the line & the nvim' window
  --    is a little bit larger than the text so that when the cursor comes
  --    closer to the window border (and on the ligature), the buffer does
  --    a side-scroll. Then the cursor does wonky stuff when moving w.r.t that
  --    end-of-line ligature.
  --
  --  * About some symbols display:
  --    The git above/below arrows on the right of my prompt.
  --
  -- experimental_shape_post_processing = true,
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
