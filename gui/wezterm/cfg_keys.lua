local wezterm = require "wezterm"
local act = wezterm.action

-- NOTE: always use wezterm.action_callback when it's in a release version!!
-- PR (by me!): https://github.com/wez/wezterm/pull/1151
local function act_callback(event_id, callback)
  if wezterm.action_callback then
    wezterm.log_info(">> wezterm.action_callback is available for this version, use it!")
    return wezterm.action_callback(callback)
  else
    wezterm.log_info(">> wezterm.action_callback is NOT available for this version, fallback to manual setup..")
    wezterm.on(event_id, callback)
    return wezterm.action{EmitEvent=event_id}
  end
end

local cfg = {}

cfg.disable_default_key_bindings = true

-- NOTE: About SHIFT and the keybind definition:
-- * For bindings with SHIFT and a letter, the `key` field (the letter)
--   can be lowercase and the mods should NOT contain 'SHIFT'.
-- * For bindings with SHIFT and something else, mod should contain SHIFT,
--   and key should be the shifted key that is going to reach the terminal.
--   (based on the keyboard-layout)
cfg.keys = {
  {mods = "SHIFT", key = "PageUp", action = act{ScrollByPage = -1}},
  {mods = "SHIFT", key = "PageDown", action = act{ScrollByPage = 1}},

  -- Wezterm features
  {mods = "CTRL|SHIFT", key = "r", action = "ReloadConfiguration"},
  {mods = "CTRL|SHIFT", key = "l", action = act{ClearScrollback = "ScrollbackAndViewport"}},
  {mods = "CTRL|SHIFT", key = "f", action = act{Search = {CaseInSensitiveString = ""}}},
  {mods = "CTRL|SHIFT", key = " ", action = "QuickSelect"},
  {mods = "CTRL|ALT",   key = " ", action = "QuickSelect"}, -- note: eats a valid terminal keybind
  {mods = "CTRL|SHIFT", key = "d", action = "ShowDebugOverlay"}, -- note: it's not a full Lua interpreter

  -- Copy/Paste to/from Clipboard
  {mods = "CTRL|SHIFT", key = "c", action = act{CopyTo = "Clipboard"}},
  {mods = "CTRL|SHIFT", key = "v", action = act{PasteFrom = "Clipboard"}},
  -- Paste from PrimarySelection (Copy is done by selection)
  {mods = "SHIFT",    key = "Insert", action = act{PasteFrom = "PrimarySelection"}},
  {mods = "CTRL|ALT", key = "v",      action = act{PasteFrom = "PrimarySelection"}},
  -- NOTE: the last one eats a valid terminal keybind

  -- Tabs
  {mods = "CTRL|SHIFT", key = "t", action = act{SpawnTab="DefaultDomain"}},
  {mods = "CTRL",       key = "Tab", action = act{ActivateTabRelative=1}},
  {mods = "CTRL|SHIFT", key = "Tab", action = act{ActivateTabRelative=-1}},
  {mods = "CTRL|SHIFT", key = "w", action = act{CloseCurrentTab={confirm=false}}},

  {mods = "CTRL|SHIFT", key = "x", action = "ShowLauncher"},

  -- Font size
  {mods = "CTRL", key = "0", action = "ResetFontSize"}, -- Ctrl-Shift-0
  {mods = "CTRL", key = "6", action = "DecreaseFontSize"}, -- Ctrl-Shift-- (key with -)
  {mods = "CTRL", key = "+", action = "IncreaseFontSize"}, -- Ctrl-Shift-+ (key with =)

  ---- custom events

  {mods = "CTRL|SHIFT", key = "g", action = act_callback("toggle-ligatures", function(win, _)
    local overrides = win:get_config_overrides() or {}
    if not overrides.harfbuzz_features then
      -- If we haven't overriden it yet, then override with ligatures disabled
      overrides.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}
    else
      -- else we did already, and we should disable the override now
      overrides.harfbuzz_features = nil
    end
    win:set_config_overrides(overrides)
  end)},
}


return cfg
