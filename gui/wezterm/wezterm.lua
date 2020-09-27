local wezterm = require "wezterm"
local inspect = require "lib/inspect"

-- My stdlib
---------------------------------------------------------------

local mytable = {} -- my "table" stdlib

--- Merge all the given tables into a single one and return it.
function mytable.merge_all(...)
  local ret = {}
  for _, tbl in ipairs({...}) do
    for k, v in pairs(tbl) do
      ret[k] = v
    end
  end
  return ret
end

--- Deep clone the given table.
function mytable.deepclone(original)
  local clone = {}
  for k, v in pairs(original) do
    if type(v) == "table" then
      clone[k] = mytable.deepclone(v)
    else
      clone[k] = v
    end
  end
  return clone
end

-- WezTerm configuration
---------------------------------------------------------------

-- Bew colors
local bew_colors = {
  background = "#202020",
  foreground = "#eeeeee",

  cursor_bg = "#eeeeee",
  cursor_fg = "#202020",

  ansi = {
    "#2F2F2F", -- blacks
    "#ff6565", -- reds
    "#4CAF50", -- greens
    "#eab93d", -- yellows
    "#5788FF", -- blues
    "#ce5c00", -- oranges (magentas usually)
    "#89b6e2", -- cyans
    "#cccccc", -- whites
  },
  brights = {
    "#555753", -- blacks
    "#ff6565", -- reds
    "#4CAF50", -- greens
    "#ffc123", -- yellows
    "#2C82F2", -- blues
    "#f57900", -- oranges (magentas usually)
    "#89b6e2", -- cyans
    "#fafafa", -- whites
  },
}

local cfg_colors_and_appearance = {
  colors = bew_colors,
  hide_tab_bar_if_only_one_tab = true,
}

-- Font
---------------------------------------------------------------

local function font_with_sym_fallback(font_family)
  -- family names, not file names
  return wezterm.font_with_fallback({
    font_family,
    "Font Awesome 5 Free Solid",
    "Noto Color Emoji", -- for emoji support, weather icons, etc...
  })
end

local cfg_fonts = {
  font_size = 13.0,

  -- default font config comes from fontconfig and manages to find a lot of fonts,
  -- but to have a more all-included config I'll list everything.
  ------------

  font_dirs = {"fonts"}, -- relative to this config file
  font_locator = "ConfigDirsOnly",

  -- FIXME (<-- this is an example of bolded text)
  font_rules = { -- must be ordered, first match will be used
    {
      italic = true,
      intensity = "Bold",
      font = font_with_sym_fallback("Iosevka Term Bold Italic"),
    },
    {
      italic = true,
      font = font_with_sym_fallback("Iosevka Term Light Italic"),
    },
    {
      intensity = "Bold",
      font = font_with_sym_fallback("Iosevka Term Bold"),
    },
  },
  font = font_with_sym_fallback("Iosevka Term Light"),
}

-- Key/Mouse bindings
---------------------------------------------------------------

local function bind_with_mods(mods, reference_bind)
  local new_bind = mytable.deepclone(reference_bind)
  new_bind.mods = mods
  return new_bind
end

-- Key bindings

local cfg_key_bindings = {
  disable_default_key_bindings = true,

  -- NOTE: for bindings with mod SHIFT, the `key` field must be uppercase'd.
  keys = {
    {mods = "SHIFT", key = "PageUp", action = wezterm.action{ScrollByPage = -1}},
    {mods = "SHIFT", key = "PageDown", action = wezterm.action{ScrollByPage = 1}},

    -- Wezterm features
    {mods = "CTRL|SHIFT", key = "R", action = "ReloadConfiguration"},
    {mods = "CTRL|SHIFT", key = "L", action = "ClearScrollback"},
    {mods = "CTRL|SHIFT", key = "F", action = wezterm.action{Search = {CaseInSensitiveString = ""}}},

    -- Copy (to Clipboard) / Paste (from Clipboard or PrimarySelection)
    {mods = "SHIFT", key = "Insert", action = "PastePrimarySelection"},
    {mods = "CTRL|SHIFT", key = "C", action = "Copy"},
    {mods = "CTRL|SHIFT", key = "V", action = "Paste"},

    -- Tabs
    {mods = "CTRL|SHIFT", key = "T", action = wezterm.action{SpawnTab="DefaultDomain"}},
    {mods = "CTRL",       key = "Tab", action = wezterm.action{ActivateTabRelative=1}},
    {mods = "CTRL|SHIFT", key = "Tab", action = wezterm.action{ActivateTabRelative=-1}},
    {mods = "CTRL|SHIFT", key = "W", action = "CloseCurrentTab"},

    -- Zoom
    {mods = "CTRL|SHIFT", key = "0", action = "ResetFontSize"},
    {mods = "CTRL|SHIFT", key = "6", action = "DecreaseFontSize"}, -- (key with -)
    {mods = "CTRL|SHIFT", key = "+", action = "IncreaseFontSize"},
  },
}

-- Mouse bindings

local mouse_bindings = {}

-- Define all mouse bindings (we disable the defaults)

-- Left click always starts a new selection.
-- The number of clicks determines the selection mode: 1:Cell 2:Word: 3:Line
function add_mouse_select(bindings, button, streak, selection_mode)
  -- Select on Down event
  table.insert(bindings, {
    mods="NONE",
    event={Down={streak=streak, button=button}},
    action=wezterm.action{SelectTextAtMouseCursor=selection_mode},
  })

  -- Extend on Drag event
  table.insert(bindings, {
    mods="NONE",
    event={Drag={streak=streak, button=button}},
    action=wezterm.action{ExtendSelectionToMouseCursor=selection_mode},
  })

  -- Complete on Up event
  table.insert(bindings, {
    mods="NONE",
    event={Up={streak=streak, button=button}},
    action="CompleteSelection",
  })
end
add_mouse_select(mouse_bindings, "Left", 1, "Cell")
add_mouse_select(mouse_bindings, "Left", 2, "Word")
add_mouse_select(mouse_bindings, "Left", 3, "Line")

-- Right click always extends the selection.
-- The number of clicks determines the selection mode: 1:Cell 2:Word: 3:Line
function add_extend_mouse_select(bindings, button, streak, selection_mode)
  -- Extend the selection on Down & Drag events
  table.insert(bindings, {
    mods="NONE",
    event={Down={streak=streak, button=button}},
    action=wezterm.action{ExtendSelectionToMouseCursor=selection_mode},
  })
  table.insert(bindings, {
    mods="NONE",
    event={Drag={streak=streak, button=button}},
    action=wezterm.action{ExtendSelectionToMouseCursor=selection_mode},
  })
end
add_extend_mouse_select(mouse_bindings, "Right", 1, "Cell")
add_extend_mouse_select(mouse_bindings, "Right", 2, "Word")
add_extend_mouse_select(mouse_bindings, "Right", 3, "Line")

-- Ctrl-Left click opens the link if any.
table.insert(mouse_bindings, {
  mods="CTRL",
  event={Up={streak=1, button="Left"}},
  action="OpenLinkAtMouseCursor",
})

-- Clipboard / PrimarySelection paste
-- Alt-Middle click pastes from the clipboard selection
table.insert(mouse_bindings, {
  mods="ALT",
  event={Down={streak=1, button="Middle"}},
  action="Paste",
})
-- Middle click pastes from the primary selection (for any other mods).
-- Wezterm wants an exact match so we must register the bind for all the mods to 'ignore'
local bind_middle_to_primary = {
  event={Down={streak=1, button="Middle"}},
  action="PastePrimarySelection",
  mods = "invalid", -- to ensure this bind is not used directly
}
table.insert(mouse_bindings, bind_with_mods("NONE", bind_middle_to_primary))
table.insert(mouse_bindings, bind_with_mods("CTRL", bind_middle_to_primary))
table.insert(mouse_bindings, bind_with_mods("SHIFT", bind_middle_to_primary))
-- make it work even when SUPER is pressed
table.insert(mouse_bindings, bind_with_mods("SUPER", bind_middle_to_primary))

local cfg_mouse_bindings = {
  disable_default_mouse_bindings = true,
  mouse_bindings = mouse_bindings,
}

-- Merge configs and return!
---------------------------------------------------------------

local config = mytable.merge_all(
  cfg_colors_and_appearance,
  cfg_fonts,
  cfg_key_bindings,
  cfg_mouse_bindings,
  {} -- so the last table can have an ending comma for git diffs :)
)

print(inspect(config))
return config
