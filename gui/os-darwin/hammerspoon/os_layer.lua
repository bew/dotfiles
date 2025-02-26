local hs = hs

local STATE = {
  alert_id = nil,
}

-- Create modal for layer-specific keybindings
-- It is enabled/disabled by the eventtap below
local OS_layer = hs.hotkey.modal.new()

-- Register hooks to add visual feedback
OS_layer.entered = function()
  -- Show a notification indefinitely (until closed)
  local style = {
    -- Make sure the alert is always visible (note: top edge not good because of the notch)
    -- and does not clutter visibility (e.g. when triggering a screenshot)
    atScreenEdge = 2, -- 2: bottom edge
    -- doc: https://www.hammerspoon.org/docs/hs.drawing.color.html
    -- Big list of pre-defined colors ( from https://en.wikipedia.org/wiki/Web_colors#X11_color_names )
    strokeColor = hs.drawing.color.x11.darkorange,
    strokeWidth = 7, -- thicker than default
  }
  STATE.alert_id = hs.alert.show(
    "OS LAYER ACTIVE",
    style,
    hs.mouse.getCurrentScreen(),
    60 -- seconds (non-number is supposed to be infinite but it's broken…)
  )
end

OS_layer.exited = function()
  hs.alert.closeSpecific(STATE.alert_id)
end

--- Setup the top binding for the OS layer
---@param opts {key: string}
function OS_layer.setup(opts)
  opts = opts or {}
  assert(opts.key, "'key' field is required to setup the OS layer (e.g. `F17`)")

  hs.hotkey.bind({}, opts.key, function() OS_layer:enter() end, function() OS_layer:exit() end)
end

return OS_layer
