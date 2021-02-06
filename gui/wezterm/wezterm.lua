-- WezTerm configuration
---------------------------------------------------------------

local wezterm = require "wezterm"
local mytable = require "lib/mystdlib".mytable

-- Misc
------------------------------------------

local cfg_misc = {
  window_close_confirmation = "NeverPrompt",
  show_update_window = false,

  -- Avoid unexpected config breakage and unusable terminal
  automatically_reload_config = false,
}

-- Colors & Appearance
------------------------------------------

-- Bew colors
local bew_colors = {
  background = "#202020",
  foreground = "#eeeeee",

  cursor_bg = "#eeeeee",
  cursor_fg = "#202020",
  cursor_border = "#eeeeee", -- same as cursor_bg

  ansi = {
    "#2F2F2F", -- black
    "#ff6565", -- red
    "#4CAF50", -- green
    "#eab93d", -- yellow
    "#5788FF", -- blue
    "#ce5c00", -- orange (magentas usually)
    "#89b6e2", -- cyan
    "#cccccc", -- white
  },
  brights = {
    "#555753", -- black
    "#ff6565", -- red
    "#4CAF50", -- green
    "#ffc123", -- yellow
    "#2C82F2", -- blue
    "#f57900", -- orange (magentas usually)
    "#89b6e2", -- cyan
    "#fafafa", -- white
  },
}

local cfg_colors_and_appearance = {
  colors = bew_colors,
  hide_tab_bar_if_only_one_tab = true,
}

-- Font
------------------------------------------

local function font_with_sym_fallback(font_family)
  -- family names, not file names
  return wezterm.font_with_fallback({
    font_family,
    "Font Awesome 5 Free Solid",
  })
end

local cfg_fonts = {
  font_size = 11.0,

  -- default font config comes from fontconfig and manages to find a lot of fonts,
  -- but to have a more all-included config I'll list everything myself.

  font_dirs = {"fonts"}, -- relative to this config file
  font_locator = "ConfigDirsOnly", -- for a pure config, but might break if fonts can't be found

  -- FIXME (<-- this is an example of bolded text)
  font = font_with_sym_fallback("Iosevka Term Extended"),
  -- Correct color changed by antialiasing.
  -- The default is Subpixel. With Subpixel, the rendered color is beige-ish
  -- and slightly darker.
  -- (explanation: https://gitter.im/wezterm/Lobby?at=5fbc5fb129cc4d7348294eb6)
  font_antialias = "Greyscale",

  -- Iosevka Font:
  -- + Has 2 variants for terminals: Term & Fixed. Fixed is same as Term but without ligatures.
  --   in the long run, I'd like to have a keybinding to enable/disable ligatures on demand,
  --   by switching font for example.
  --   --> for now, use Term (with ligatures)
  --
  -- + Has 2 additional variants for horizontal size: Normal & Extended. The Normal is the one
  --   which does not mention 'Extended'. Extended is wider than Normal.
  --   --> use Extended variant, the normal one is way too thin!!!

  allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
}

-- Key/Mouse bindings
------------------------------------------

-- Key bindings

local cfg_key_bindings = {
  disable_default_key_bindings = true,

  -- NOTE: For bindings with mod SHIFT and a letter, the `key` field (the letter)
  --       must be uppercase'd and the mods should NOT contain 'SHIFT'.
  keys = {
    {mods = "SHIFT", key = "PageUp", action = wezterm.action{ScrollByPage = -1}},
    {mods = "SHIFT", key = "PageDown", action = wezterm.action{ScrollByPage = 1}},

    -- Wezterm features
    {mods = "CTRL", key = "R", action = "ReloadConfiguration"}, -- Ctrl-Shift-r
    {mods = "CTRL", key = "L", action = wezterm.action{ClearScrollback = "ScrollbackAndViewport"}}, -- Ctrl-Shift-l
    {mods = "CTRL", key = "F", action = wezterm.action{Search = {CaseInSensitiveString = ""}}}, -- Ctrl-Shift-f

    -- Copy (to Clipboard) / Paste (from Clipboard or PrimarySelection)
    {mods = "CTRL", key = "C", action = wezterm.action{CopyTo = "Clipboard"}}, -- Ctrl-Shift-c
    {mods = "CTRL", key = "V", action = wezterm.action{PasteFrom = "Clipboard"}}, -- Ctrl-Shift-v
    {mods = "SHIFT", key = "Insert", action = wezterm.action{PasteFrom = "PrimarySelection"}},

    -- Tabs
    {mods = "CTRL",       key = "T", action = wezterm.action{SpawnTab="DefaultDomain"}}, -- Ctrl-Shift-t
    {mods = "CTRL",       key = "Tab", action = wezterm.action{ActivateTabRelative=1}},
    {mods = "CTRL|SHIFT", key = "Tab", action = wezterm.action{ActivateTabRelative=-1}},
    {mods = "CTRL",       key = "W", action = wezterm.action{CloseCurrentTab={confirm=false}}}, -- Ctrl-Shift-w

    -- Font size
    {mods = "CTRL|SHIFT", key = "0", action = "ResetFontSize"}, -- Ctrl-Shift-0
    {mods = "CTRL|SHIFT", key = "6", action = "DecreaseFontSize"}, -- Ctrl-Shift-- (key with -)
    {mods = "CTRL|SHIFT", key = "+", action = "IncreaseFontSize"}, -- Ctrl-Shift-+
  },
}

-- Mouse bindings

-- Define all mouse bindings (defaults are disabled)

local mouse_bindings = {}

-- Left click always starts a new selection.
-- The number of clicks determines the selection mode: 1:Cell 2:Word: 3:Line
function binds_for_mouse_select(button, streak, selection_mode)
  return {
    -- Select on Down event
    {
      mods="NONE",
      event={Down={streak=streak, button=button}},
      action=wezterm.action{SelectTextAtMouseCursor=selection_mode},
    },

    -- Extend on Drag event
    {
      mods="NONE",
      event={Drag={streak=streak, button=button}},
      action=wezterm.action{ExtendSelectionToMouseCursor=selection_mode},
    },

    -- Complete on Up event
    {
      mods="NONE",
      event={Up={streak=streak, button=button}},
      action=wezterm.action{CompleteSelection="PrimarySelection"}
    },
  }
end
table.insert(mouse_bindings, {
  binds_for_mouse_select("Left", 1, "Cell"),
  binds_for_mouse_select("Left", 2, "Word"),
  binds_for_mouse_select("Left", 3, "Line"),
})

-- Right click always extends the selection.
-- The number of clicks determines the selection mode: 1:Cell 2:Word: 3:Line
function binds_extend_mouse_select(button, streak, selection_mode)
  return {
    -- Extend the selection on Down & Drag events
    {
      mods="NONE",
      event={Down={streak=streak, button=button}},
      action=wezterm.action{ExtendSelectionToMouseCursor=selection_mode},
    },
    {
      mods="NONE",
      event={Drag={streak=streak, button=button}},
      action=wezterm.action{ExtendSelectionToMouseCursor=selection_mode},
    },
  }
end
table.insert(mouse_bindings, {
  binds_extend_mouse_select("Right", 1, "Cell"),
  binds_extend_mouse_select("Right", 2, "Word"),
  binds_extend_mouse_select("Right", 3, "Line"),
})

-- Ctrl-Left click opens the link under the mouse pointer if any.
table.insert(mouse_bindings, {
  mods="CTRL",
  event={Up={streak=1, button="Left"}},
  action="OpenLinkAtMouseCursor",
})

-- Clipboard / PrimarySelection paste
table.insert(mouse_bindings, {
  -- Middle click pastes from the primary selection (for any other mods).
  wezterm.permute_any_or_no_mods({
    event={Down={streak=1, button="Middle"}},
    action=wezterm.action{PasteFrom = "PrimarySelection"},
  }),
  -- Alt-Middle click pastes from the clipboard selection
  -- NOTE: Must be last to overwrite the existing Alt-Middle binding done by permute_any_or_no_mods.
  {
    mods="ALT",
    event={Down={streak=1, button="Middle"}},
    action=wezterm.action{PasteFrom = "Clipboard"},
  },
})

local cfg_mouse_bindings = {
  disable_default_mouse_bindings = true,
  -- To simplify config composability, `mouse_bindings` is a
  -- nested list of (bind or list of (bind or ...)), so we must
  -- flatten the list first.
  mouse_bindings = mytable.flatten_list(mouse_bindings),
}

-- Merge configs and return!
------------------------------------------

local config = mytable.merge_all(
  cfg_misc,
  cfg_colors_and_appearance,
  cfg_fonts,
  cfg_key_bindings,
  cfg_mouse_bindings,
  {} -- so the last table can have an ending comma for git diffs :)
)

return config
