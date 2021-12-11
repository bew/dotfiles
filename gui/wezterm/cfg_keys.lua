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

-- IDEA: A better action syntax, see: https://github.com/wez/wezterm/issues/1150

-- IDEA: helper for keybind definition
local function keybind(mods, key, action)
  return {mods = mods, key = key, action = action}
end
local ctrl_shift = "CTRL|SHIFT"

local cfg = {}

cfg.disable_default_key_bindings = true

-- NOTE: About SHIFT and the keybind definition:
-- * For bindings with SHIFT and a letter, the `key` field (the letter)
--   can be lowercase and the mods should NOT contain 'SHIFT'.
-- * For bindings with SHIFT and something else, mod should contain SHIFT,
--   and key should be the shifted key that is going to reach the terminal.
--   (based on the keyboard-layout)
cfg.keys = {
  keybind("SHIFT", "PageUp", act{ScrollByPage = -1}),
  keybind("SHIFT", "PageDown", act{ScrollByPage = 1}),

  -- Wezterm features
  keybind(ctrl_shift, "r", "ReloadConfiguration"),
  keybind(ctrl_shift, "l", act{ClearScrollback = "ScrollbackAndViewport"}),
  keybind(ctrl_shift, "f", act{Search = {CaseInSensitiveString = ""}}),
  keybind(ctrl_shift, " ", "QuickSelect"),
  keybind("CTRL|ALT", " ", "QuickSelect"), -- note: eats a valid terminal keybind
  keybind(ctrl_shift, "d", "ShowDebugOverlay"), -- note: it's not a full Lua interpreter

  -- Copy/Paste to/from Clipboard
  keybind(ctrl_shift, "c", act{CopyTo = "Clipboard"}),
  keybind(ctrl_shift, "v", act{PasteFrom = "Clipboard"}),
  -- Paste from PrimarySelection (Copy is done by selection)
  keybind("SHIFT",    "Insert", act{PasteFrom = "PrimarySelection"}),
  keybind("CTRL|ALT", "v",      act{PasteFrom = "PrimarySelection"}),
  -- NOTE: that last one eats a valid terminal keybind

  -- Smart copy with Alt-c:
  -- - If active selection, will copy it to Clipboard & Primary
  -- - If NO selection, sends Alt-c to the running program
  keybind("ALT", "c", act_callback("smart-copy", function(win, pane)
    local has_selection = win:get_selection_text_for_pane(pane) ~= ""
    if has_selection then
      win:perform_action(act{CopyTo="ClipboardAndPrimarySelection"}, pane)
    else
      -- FIXME: for some reason, adding 'act' (wezterm.action) for 'SendKey' breaks the call..
      --   WHY?? It's not consistent with all other actions..
      win:perform_action({SendKey={mods="ALT", key="c"}}, pane)
    end
  end)),

  -- Tabs
  keybind(ctrl_shift, "t", act{SpawnTab="DefaultDomain"}),
  keybind("CTRL",     "Tab", act{ActivateTabRelative=1}),
  keybind(ctrl_shift, "Tab", act{ActivateTabRelative=-1}),
  keybind(ctrl_shift, "w", act{CloseCurrentTab={confirm=false}}),

  keybind(ctrl_shift, "x", "ShowLauncher"),

  -- Font size
  keybind("CTRL", "0", "ResetFontSize"), -- Ctrl-Shift-0
  keybind("CTRL", "+", "IncreaseFontSize"), -- Ctrl-Shift-+
  keybind("CTRL", "6", "DecreaseFontSize"), -- Ctrl-Shift-- (key with -)

  ---- custom events

  keybind(ctrl_shift, "g", act_callback("toggle-ligatures", function(win, _)
    local overrides = win:get_config_overrides() or {}
    if not overrides.harfbuzz_features then
      -- If we haven't overriden it yet, then override with ligatures disabled
      overrides.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}
    else
      -- else we did already, and we should disable the override now
      overrides.harfbuzz_features = nil
    end
    win:set_config_overrides(overrides)
  end)),
}


return cfg
