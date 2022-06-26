local wezterm = require "wezterm"
local mytable = require "lib/mystdlib".mytable
local mods = require "cfg_utils".mods

local act = wezterm.action
local act_callback = wezterm.action_callback

local cfg = {}

-- Helper for keybind definition
local function keybind(mods, keys, action)
  local keys = (type(keys) == "table") and keys or {keys}
  local mods = tostring(mods)
  local binds = {}
  for _, key in ipairs(keys) do
    table.insert(binds, {mods = mods, key = key, action = action})
  end
  return binds
end

cfg.disable_default_key_bindings = true

cfg.key_tables = {}
local function define_and_activate_keytable(spec)
  -- Flatten keys, and define the Key Table
  cfg.key_tables[spec.name] = mytable.flatten_list(spec.keys)

  -- Setup & return activation key bind
  local activation_opts = spec.activation or {}
  activation_opts.name = spec.name
  return act.ActivateKeyTable(activation_opts)
end

-- NOTE: About SHIFT and the keybind definition:
-- * For bindings with SHIFT and a letter, the `key` field (the letter)
--   can be lowercase and the mods should NOT contain 'SHIFT'.
-- * For bindings with SHIFT and something else, mod should contain SHIFT,
--   and key should be the shifted key that is going to reach the terminal.
--   (based on the keyboard-layout)
cfg.keys = {
  keybind(mods.S, "PageUp",   act.ScrollByPage(-1)),
  keybind(mods.S, "PageDown", act.ScrollByPage(1)),

  keybind(ctrl_shift, "r", act.ReloadConfiguration),
  -- keybind(mods.CS, "r", act.EmitEvent("my-reload-config-with-notif")),

  keybind(mods.CS, "l", act.ClearScrollback("ScrollbackAndViewport")),
  keybind(mods.CS, " ", act.QuickSelect),
  keybind(mods.CA, " ", act.QuickSelect), -- note: eats a valid term input
  keybind(mods.CS, "d", act.ShowDebugOverlay),
  keybind(mods.CS, "y", act.ActivateCopyMode),
  -- note: last search is now prefilled, may need to clear it first with Ctrl-u
  keybind(mods.CS, "f", act.Search{CaseInSensitiveString = ""}),

  -- Copy/Paste to/from Clipboard
  keybind(mods.CS, "c", act.CopyTo("Clipboard")),
  keybind(mods.CS, "v", act.PasteFrom("Clipboard")),
  -- Paste from PrimarySelection (Copy is done by selection)
  keybind(mods.S,  "Insert", act.PasteFrom("PrimarySelection")),
  keybind(mods.CA, "v",      act.PasteFrom("PrimarySelection")), -- note: eats a valid term input

  -- Smart copy with Alt-c:
  -- - If active selection, will copy it to Clipboard & Primary
  -- - If NO selection, sends Alt-c to the running program
  keybind(mods.A, "c", act_callback(function(win, pane)
    local has_selection = win:get_selection_text_for_pane(pane) ~= ""
    if has_selection then
      win:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
    else
      win:perform_action(act.SendKey{mods=mods.A, key="c"}, pane)
    end
  end)),

  -- Tabs
  keybind(mods.CS, "t", act.SpawnTab("DefaultDomain")),
  keybind(mods.C,  "Tab", act.ActivateTabRelative(1)),
  keybind(mods.CS, "Tab", act.ActivateTabRelative(-1)),
  keybind(mods.CS, "w", act.CloseCurrentTab{confirm=false}),

  keybind(mods.CS, "x", act.ShowLauncher),

  -- Font size
  keybind(mods.C, "0", act.ResetFontSize),    -- Ctrl-Shift-0
  keybind(mods.C, "+", act.IncreaseFontSize), -- Ctrl-Shift-+ (key with +)
  keybind(mods.C, "6", act.DecreaseFontSize), -- Ctrl-Shift-- (key with -)

  -- Toggle font ligatures
  keybind(mods.CS, "g", act_callback(function(win, _)
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


  -- Key Table: Panes Management
  keybind(mods.CS, "p", define_and_activate_keytable{
    name = "my-panes-management",
    activation = {one_shot=false, replace_current=false},
    keys = {
      keybind(mods._, "Escape", act.PopKeyTable),
      keybind(mods.CS, "p", act.PopKeyTable),


      -- Create
      keybind(mods.CSA, {"h", "LeftArrow"},  act.SplitPane{direction="Left"}),
      keybind(mods.CSA, {"j", "DownArrow"},  act.SplitPane{direction="Down"}),
      keybind(mods.CSA, {"k", "UpArrow"},    act.SplitPane{direction="Up"}),
      keybind(mods.CSA, {"l", "RightArrow"}, act.SplitPane{direction="Right"}),
      -- Destroy
      keybind(mods.CS, "d", act.CloseCurrentPane{confirm=true}),

      -- Navigation
      keybind(mods.CS, {"h", "LeftArrow"},  act.ActivatePaneDirection("Left")),
      keybind(mods.CS, {"j", "DownArrow"},  act.ActivatePaneDirection("Down")),
      keybind(mods.CS, {"k", "UpArrow"},    act.ActivatePaneDirection("Up")),
      keybind(mods.CS, {"l", "RightArrow"}, act.ActivatePaneDirection("Right")),
      keybind(mods.CS, "Space", act.PaneSelect{mode="Activate"}),

      -- Manipulation
      keybind(mods.CS, "s", act.PaneSelect{mode="SwapWithActive"}),
      keybind(mods.CS, "z", act.TogglePaneZoomState),
    },
  }),
}
-- FIXME: redefining the 'copy_mode' key_table will remove default 'copy_mode' keys.
--        (probably due to disable_default_key_bindings=true)
-- TODO(IDEA): suggest `wezterm.default_config.key_tables.copy_mode` on which I could add my own 'i' key!
--             (maybe as a getter, to make it explicit we're getting a fresh list of keys?)
-- TODO(IDEA): suggest adding a 'wezterm' or 'builtin' prefix to existing tables,
--             to 'reserve' a set of tables for potential future uses
-- cfg.key_tables.copy_mode = {
--   {key="i", mods="NONE", action=act.CopyMode("Close")},
-- }

-- To simplify config composability, `cfg.keys` is (initially) a
-- nested list of (bind or list of (bind or ...)), so we must
-- flatten the list to have a list of bind.
cfg.keys = mytable.flatten_list(cfg.keys)

return cfg
