
local col = {}

-- Bew colors
col.background = "#191919"
col.foreground = "#eeeeee"

col.cursor_bg = "#eeeeee"
col.cursor_fg = "#202020"
col.cursor_border = "#eeeeee" -- same as cursor_bg

col.ansi = {
  "#2F2F2F", -- black
  "#ff6565", -- red
  "#4CAF50", -- green
  "#eab93d", -- yellow
  "#5788FF", -- blue
  "#ce5c00", -- orange (magentas usually)
  "#89b6e2", -- cyan
  "#cccccc", -- white
}

col.brights = {
  "#555753", -- black
  "#ff6565", -- red
  "#4CAF50", -- green
  "#ffc123", -- yellow
  "#2C82F2", -- blue
  "#f57900", -- orange (magentas usually)
  "#89b6e2", -- cyan
  "#fafafa", -- white
}

-- Slightly red & transparent (blended in bg)
-- (fg color is preserved)
col.selection_bg = "rgba(100% 50% 50% 20%)"

return col
