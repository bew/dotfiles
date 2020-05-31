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

-- Change the default click behavior
-- > LeftClick only selects text and doesn't open hyperlinks
-- > CTRL-LeftClick open hyperlinks
table.insert(mouse_bindings, {
  mods="NONE",
  event={Down={streak=1, button="Left"}},
  action="CompleteSelection",
})
table.insert(mouse_bindings, {
  mods="CTRL",
  event={Down={streak=1, button="Left"}},
  action="OpenLinkAtMouseCursor",
})

-- Clipboard / PrimarySelection paste
-- > ALT-MiddleClick pastes from the clipboard
-- > MiddleClick pastes from the primary selection (for any mods)
table.insert(mouse_bindings, {
  mods="ALT",
  event={Down={streak=1, button="Middle"}},
  action="Paste",
})
-- Wezterm wants an exact match so we must register the bind for all the mods we want to 'ignore'
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

local cfg_mouse_bindings = { mouse_bindings = mouse_bindings }

print("------ MOUSE BINDINGS ------")
print(inspect(cfg_mouse_bindings))

-- Merge configs and return!
---------------------------------------------------------------

return mytable.merge_all(
  cfg_colors_and_appearance,
  cfg_key_bindings,
  cfg_mouse_bindings,
  {} -- so the last table can have an ending comma for git diffs :)
)
