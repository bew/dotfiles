-- TODO: setup annotations for LuaLS
local hs = hs

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

actions.reload = function()
  hs.reload()
end

actions.screenshot = function()
  os.execute("screencapture -iUc")
end

local OS = require"os_layer"
OS.setup { key = "F17" }

-- FIXME: need to bind both to ctrl & cmd since the key currently changes when Terminal in focus or not..
-- .. not sure how to _fix_ this, maybe just have a simple helper that binds both?

OS:bind({"ctrl"}, "r", actions.reload)
OS:bind({"cmd"}, "r", actions.reload)

OS:bind({"ctrl"}, "s", actions.screenshot)
OS:bind({"cmd"}, "s", actions.screenshot)

-- TODO: block any key that is not bound to the OS layer 👀
-- TODO: have a callback where there is an error with the config?

config_reloaded() -- should be last!
