local wezterm = require "wezterm"

local cfg = {}

cfg.disable_default_key_bindings = true

  -- NOTE: For bindings with mod SHIFT and a letter, the `key` field (the letter)
  --       must be uppercase'd and the mods should NOT contain 'SHIFT'.
cfg.keys = {
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

  {mods = "CTRL", key = "X", action = "ShowLauncher"},

  -- Font size
  {mods = "CTRL", key = "0", action = "ResetFontSize"}, -- Ctrl-Shift-0
  {mods = "CTRL", key = "6", action = "DecreaseFontSize"}, -- Ctrl-Shift-- (key with -)
  {mods = "CTRL", key = "+", action = "IncreaseFontSize"}, -- Ctrl-Shift-+ (key with =)
}

return cfg
