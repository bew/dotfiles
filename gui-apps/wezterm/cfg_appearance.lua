local cfg = {}

cfg.hide_tab_bar_if_only_one_tab = true

-- Pad window to avoid the content to be too close to the border,
-- so it's easier to see and select.
cfg.window_padding = {
  left = 5, right = 5,
  top = 5, bottom = 5,
}

cfg.inactive_pane_hsb = {
  -- NOTE: these values are multipliers, applied on normal pane values
  brightness = 0.7,
}

cfg.colors = require("cfg_bew_colors")

return cfg
