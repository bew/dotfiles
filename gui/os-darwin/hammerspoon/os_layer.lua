---@diagnostic disable-next-line: undefined-global
local hs = hs

---@class myhs._OS_State
---@field alert_id number?
---@field is_pressed boolean
local STATE = {
  alert_id = nil,
  is_pressed = false,
}

-- Create modal for layer-specific keybindings
-- It is enabled/disabled by the eventtap below
local OS_layer = hs.hotkey.modal.new()

-- Register hooks to add visual feedback
function OS_layer.show_popup()
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

function OS_layer.close_popup()
  hs.alert.closeSpecific(STATE.alert_id)
end

--- Setup the top binding for the OS layer
---@param opts {key: string}
function OS_layer.setup(opts)
  opts = opts or {}
  assert(opts.key, "'key' field is required to setup the OS layer (e.g. `F17`)")

  hs.hotkey.bind(
    {}, opts.key,
    function()
      print("OS key is pressed")
      STATE.is_pressed = true
      OS_layer:enter() -- activate the layer
      OS_layer:show_popup()
    end,
    function()
      print("OS key is released")
      STATE.is_pressed = false
      OS_layer:exit() -- exit the layer
      OS_layer:close_popup()
    end
  )
end

function OS_layer.wrap_nopopup_action(action_fn)
  return function()
    OS_layer.close_popup()
    -- Execute the action function after a little while, to allow the GUI to update & close the
    -- popup before triggering the action.
    -- note: 0.1 is slightly too short, the popup doesn't completely hide before the action 😬
    hs.timer.doAfter(0.15, function()
      local ok, err = pcall(action_fn)
      if STATE.is_pressed then
        -- OS key is still pressed, show the popup again
        OS_layer.show_popup()
      end
      -- bubble-up the error if any
      if not ok then error(err) end
    end)
  end
end

return OS_layer
