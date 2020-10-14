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

local is_list = function(t)
  if type(t) ~= "table" then
    return false
  end
  -- a list has list indices, an object does not
  return ipairs(t)(t, 0) and true or false
end

--- Flatten the given list of (item or (list of (item or ...)) to a list of item.
-- (nested lists are supported)
function mytable.flatten_list(list)
  local flattened_list = {}
  for _, item in ipairs(list) do
    if is_list(item) then
      for _, sub_item in ipairs(mytable.flatten_list(item)) do
        table.insert(flattened_list, sub_item)
      end
    else
      table.insert(flattened_list, item)
    end
  end
  return flattened_list
end

-- WezTerm configuration
---------------------------------------------------------------

-- Bew colors
local bew_colors = {
  background = "#202020",
  foreground = "#eeeeee",

  cursor_border = "#eeeeee",
  cursor_bg = "#eeeeee",
  cursor_fg = "#202020",

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
    "Noto Color Emoji", -- for emoji support, weather icons, etc...
  })
end

local cfg_fonts = {
  font_size = 11.0,

  -- default font config comes from fontconfig and manages to find a lot of fonts,
  -- but to have a more all-included config I'll list everything myself.

  font_dirs = {"fonts"}, -- relative to this config file
  font_locator = "ConfigDirsOnly", -- for a pure config, but might break if fonts can't be found

  -- FIXME (<-- this is an example of bolded text)
  font_rules = { -- must be ordered, first match will be used
    {
      italic = true,
      intensity = "Bold",
      font = font_with_sym_fallback("Iosevka Term Bold Extended Italic"),
    },
    {
      italic = true,
      font = font_with_sym_fallback("Iosevka Term Light Extended Italic"),
    },
    {
      intensity = "Bold",
      -- FIXME: this bold font is too heavy (compared to my font on urxvt)
      font = font_with_sym_fallback("Iosevka Term Bold Extended"),
    },
  },
  font = font_with_sym_fallback("Iosevka Term Light Extended"),

  -- Iosevka Font:
  -- + Has 2 variants for terminals: Term & Fixed. Fixed is same as Term but without ligatures.
  --   in the long run, I'd like to have a keybinding to enable/disable ligatures on demand,
  --   by switching font for example.
  --   --> for now, use Term (with ligatures)
  --
  -- + Has 2 additional variants for horizontal size: Normal & Extended. The Normal is the one
  --   which does not mention 'Extended'. Extended is wider than Normal.
  --   --> use Extended variant, the normal one is way too thin!!!
}

-- Key/Mouse bindings
------------------------------------------

local function binds_with_any_mods(all_mods, reference_bind)
  local bindings = {}
  for _, mod in ipairs(all_mods) do
    local new_bind = mytable.deepclone(reference_bind)
    new_bind.mods = mod
    table.insert(bindings, new_bind)
  end
  return bindings
end

-- Key bindings

local cfg_key_bindings = {
  disable_default_key_bindings = true,

  -- NOTE: for bindings with mod SHIFT, the `key` field must be uppercase'd.
  -- FIXME: fixed in nightly, will need to update my bindings on next stable.
  keys = {
    {mods = "SHIFT", key = "PageUp", action = wezterm.action{ScrollByPage = -1}},
    {mods = "SHIFT", key = "PageDown", action = wezterm.action{ScrollByPage = 1}},

    -- Wezterm features
    {mods = "CTRL|SHIFT", key = "R", action = "ReloadConfiguration"},
    {mods = "CTRL|SHIFT", key = "L", action = "ClearScrollback"},
    {mods = "CTRL|SHIFT", key = "F", action = wezterm.action{Search = {CaseInSensitiveString = ""}}},

    -- Copy (to Clipboard) / Paste (from Clipboard or PrimarySelection)
    {mods = "CTRL|SHIFT", key = "C", action = "Copy"},
    {mods = "CTRL|SHIFT", key = "V", action = "Paste"},
    {mods = "SHIFT", key = "Insert", action = "PastePrimarySelection"},

    -- Tabs
    {mods = "CTRL|SHIFT", key = "T", action = wezterm.action{SpawnTab="DefaultDomain"}},
    {mods = "CTRL",       key = "Tab", action = wezterm.action{ActivateTabRelative=1}},
    {mods = "CTRL|SHIFT", key = "Tab", action = wezterm.action{ActivateTabRelative=-1}},
    {mods = "CTRL|SHIFT", key = "W", action = "CloseCurrentTab"},

    -- Font size
    {mods = "CTRL|SHIFT", key = "0", action = "ResetFontSize"},
    {mods = "CTRL|SHIFT", key = "6", action = "DecreaseFontSize"}, -- (key with -)
    {mods = "CTRL|SHIFT", key = "+", action = "IncreaseFontSize"},
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
      action="CompleteSelection",
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
  -- Alt-Middle click pastes from the clipboard selection
  {
    mods="ALT",
    event={Down={streak=1, button="Middle"}},
    action="Paste",
  },
  -- Middle click pastes from the primary selection (for any other mods).
  -- Wezterm wants an exact match so we must register the bind for all the mods to 'ignore'
  binds_with_any_mods({"NONE", "CTRL", "SHIFT", "SUPER"}, {
    event={Down={streak=1, button="Middle"}},
    action="PastePrimarySelection",
  }),
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
  cfg_colors_and_appearance,
  cfg_fonts,
  cfg_key_bindings,
  cfg_mouse_bindings,
  {} -- so the last table can have an ending comma for git diffs :)
)

print(inspect(config))
return config
