local wezterm = require "wezterm"
local mytable = require "lib/mystdlib".mytable
local mods = require "cfg_utils".mods

local act = wezterm.action

local cfg = {}

cfg.disable_default_mouse_bindings = true


local mouse_bindings = {}

local function binds_for_mouse_actions(mods, button, streak, mouse_actions)
  local function mouse_bind_for(event_kind, action)
    return {
      mods=mods,
      event = {
        [event_kind] = {
          streak = streak,
          button = button
        }
      },
      action = action,
    }
  end

  local binds = {}
  if mouse_actions.down_action then
    table.insert(binds, mouse_bind_for("Down", mouse_actions.down_action))
  end
  if mouse_actions.drag_action then
    table.insert(binds, mouse_bind_for("Drag", mouse_actions.drag_action))
  end
  if mouse_actions.up_action then
    table.insert(binds, mouse_bind_for("Up", mouse_actions.up_action))
  end
  return binds
end

local function initial_selection_mouse_actions(selection_mode)
  return {
    -- Select on Down event
    down_action = act.SelectTextAtMouseCursor(selection_mode),
    -- Extend on Drag event
    drag_action = act.ExtendSelectionToMouseCursor(selection_mode),
    -- Complete & Copy on Up event
    up_action   = act.CompleteSelection("ClipboardAndPrimarySelection"),
  }
end
-- Left click always starts a new selection.
-- The number of clicks determines the selection mode: 1:Cell 2:Word: 3:Line & Alt+1:Block
table.insert(mouse_bindings, {
  binds_for_mouse_actions(mods._, "Left", 1, initial_selection_mouse_actions("Cell")),
  binds_for_mouse_actions(mods._, "Left", 2, initial_selection_mouse_actions("Word")),
  binds_for_mouse_actions(mods._, "Left", 3, initial_selection_mouse_actions("Line")),
  binds_for_mouse_actions(mods.A, "Left", 1, initial_selection_mouse_actions("Block")),
})


local function extend_selection_mouse_actions(selection_mode)
  return {
    -- Extend the selection on Down & Drag events
    down_action = act.ExtendSelectionToMouseCursor(selection_mode),
    drag_action = act.ExtendSelectionToMouseCursor(selection_mode),
    -- Complete & Copy on Up event
    up_action   = act.CompleteSelection("ClipboardAndPrimarySelection"),
  }
end
-- Right click always extends the selection.
-- The number of clicks determines the selection mode: 1:Cell 2:Word: 3:Line & Alt+1:Block
table.insert(mouse_bindings, {
  binds_for_mouse_actions(mods._, "Right", 1, extend_selection_mouse_actions("Cell")),
  binds_for_mouse_actions(mods._, "Right", 2, extend_selection_mouse_actions("Word")),
  binds_for_mouse_actions(mods._, "Right", 3, extend_selection_mouse_actions("Line")),
  binds_for_mouse_actions(mods.A, "Right", 1, extend_selection_mouse_actions("Block")),
})

-- Ctrl-Left click (on Up) opens the link under the mouse pointer if any.
-- (on Down, the click is disabled. This is to avoid bugging the running
-- program which would receive _only_ the down event and not the up event)
table.insert(mouse_bindings, {
  binds_for_mouse_actions(mods.C, "Left", 1, {
    down_action = act.Nop,
    up_action   = act.OpenLinkAtMouseCursor,
  }),
})
-- FIXME: I want this to work EVEN IF the current program enabled mouse-reporting.
--        Currently I have to press Ctrl-Shift-click to make this binding work.
-- Opened issue: https://github.com/wez/wezterm/issues/581

-- Clipboard
table.insert(mouse_bindings, {
  -- Middle click pastes
  wezterm.permute_any_or_no_mods({
    event={Down={streak=1, button="Middle"}},
    action=act.PasteFrom("Clipboard"),
  }),
})

-- Scrolling!
-- Since 20220807-113146-c2fee766 the WheelUp/WheelDown events can be bound to
-- custom actions. When using `disable_default_mouse_bindings=true`, scrolling
-- is completely disabled and we need to enable it again.
table.insert(mouse_bindings, {
  {
    mods=mods._,
    event={Down={streak=1, button={WheelUp=1}}},
    action=act.ScrollByCurrentEventWheelDelta,
  },
  {
    mods=mods._,
    event={Down={streak=1, button={WheelDown=1}}},
    action=act.ScrollByCurrentEventWheelDelta,
  },
})

-- To simplify config composability, `mouse_bindings` is a
-- nested list of (bind or list of (bind or ...)), so we must
-- flatten the list first.
cfg.mouse_bindings = mytable.flatten_list(mouse_bindings)

return cfg
