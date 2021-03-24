local wezterm = require "wezterm"
local mytable = require "lib/mystdlib".mytable

local cfg = {}

cfg.disable_default_mouse_bindings = true


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

    -- Complete on Up event
    {
      mods="NONE",
      event={Up={streak=streak, button=button}},
      action=wezterm.action{CompleteSelection="PrimarySelection"}
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

  -- To simplify config composability, `mouse_bindings` is a
  -- nested list of (bind or list of (bind or ...)), so we must
  -- flatten the list first.
cfg.mouse_bindings = mytable.flatten_list(mouse_bindings)

return cfg
