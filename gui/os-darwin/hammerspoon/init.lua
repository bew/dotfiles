-- TODO: setup annotations for LuaLS
---@diagnostic disable-next-line: undefined-global
local hs = hs

local OS = require"os_layer"

-- Change default style of alerts (default has too much roundness..)
hs.alert.defaultStyle.strokeWidth = 5
hs.alert.defaultStyle.padding = 10
hs.alert.defaultStyle.radius = 20
-- doc: https://www.hammerspoon.org/docs/hs.drawing.color.html
-- Big list of pre-defined colors ( from https://en.wikipedia.org/wiki/Web_colors#X11_color_names )
hs.alert.defaultStyle.strokeColor = hs.drawing.color.x11.lightseagreen


local reloading_alert_id = hs.alert.show("HS config reloading…")
local function config_reloaded()
  hs.alert.closeSpecific(reloading_alert_id)
  hs.alert.show("HS config reloaded!")
end

_G.actions = {}
_G.lib = {}

actions.reload = function()
  print("reloading!")
  hs.reload()
end

actions.screenshot = OS.wrap_nopopup_action(function()
  os.execute("screencapture -iUc")
end)

OS.setup { key = "F17" }

-- FIXME: need to bind both to ctrl & cmd since the key currently changes when Terminal in focus or not..
-- .. not sure how to _fix_ this, maybe just have a simple helper that binds both?

OS:bind({"ctrl"}, "r", actions.reload)
OS:bind({"cmd"}, "r", actions.reload)

OS:bind({"ctrl"}, "s", actions.screenshot)
OS:bind({"cmd"}, "s", actions.screenshot)

-- Window management

hs.grid.setGrid(hs.geometry.size(7, 7))

actions.wm = {}
lib.wm = {}

lib.wm.win_is_maximized = function(win)
  local winFrame = win:frame()
  local screenFrame = win:screen():frame()
  return winFrame:equals(screenFrame)
end

actions.wm.focusLeft = function() hs.window.focusedWindow():focusWindowWest() end
actions.wm.focusDown = function() hs.window.focusedWindow():focusWindowSouth() end
actions.wm.focusUp = function() hs.window.focusedWindow():focusWindowNorth() end
actions.wm.focusRight = function() hs.window.focusedWindow():focusWindowEast() end

actions.wm.centerOnScreen = function() hs.window.focusedWindow():centerOnScreen() end
actions.wm.toggleMaximized = function()
  local win = hs.window.focusedWindow()
  if not lib.wm.win_is_maximized(win) then
    -- NOTE: cannot use the `hs.grid.maximizeWindow(win)` because it's not a _true_ maximization
    -- (or would need to change the `win_is_maximized()` fn to detect win that is maximized in the
    -- grid, not the screen)
    win:maximize()
    -- FIXME: Firefox is VERY WEIRD when I attempt to maximize it
    -- (it does not fully maximize, and I have to repeat the action until it is fully maximized..)
  else
    local grid = hs.grid.getGrid(win:screen())
    hs.grid.set(win, {1, 1, grid.w -2, grid.h -2}, win:screen())
  end
end

actions.wm.moveWinToNextScreen = function()
  local win = hs.window.focusedWindow()
  if not win then return end

  local current_screen = win:screen()
  local next_screen = current_screen:next()
  if next_screen then
    win:moveToScreen(next_screen, --[[noResize]]true, --[[ensureInScreenBounds]]true, --[[duration]]0)
    -- Move mouse cursor to center of new screen
    local win_frame = win:frame()
    local center = hs.geometry.rectMidPoint(win_frame)
    hs.mouse.absolutePosition(center)
  end
end

OS:bind({}, "h", actions.wm.focusLeft)
OS:bind({}, "j", actions.wm.focusDown)
OS:bind({}, "k", actions.wm.focusUp)
OS:bind({}, "l", actions.wm.focusRight)

OS:bind({"cmd"}, "space", actions.wm.centerOnScreen)
OS:bind({"ctrl"}, "space", actions.wm.centerOnScreen)

OS:bind({}, "m", actions.wm.toggleMaximized)

OS:bind({"shift"}, "s", actions.wm.moveWinToNextScreen)

-- TODO: block any key that is not bound to the OS layer 👀

config_reloaded() -- should be last!
