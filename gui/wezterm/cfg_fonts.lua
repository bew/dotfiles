local wezterm = require "wezterm"

local cfg = {}

-- Disable annoying default behaviors
cfg.adjust_window_size_when_changing_font_size = false
-- !! this one opens a separate win on first unknown glyph, stealing windows focus !!
cfg.warn_about_missing_glyphs = false

cfg.font_size = 12.0

-- Makes FontAwesome's double-width glyphs display properly!
cfg.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"

-- Additional font directory (necessary to find FontAwesome font!)
cfg.font_dirs = {"fonts"} -- relative to main config file

local function font_with_fallback(font_family)
  -- family names, not file names
  return wezterm.font_with_fallback({
    font_family,
    "Font Awesome 5 Free Solid", -- nice double-spaced symbols!
  })
end

local function font_and_rules_for_iosevka()
  -- Iosevka Font:
  -- + Has 2 variants for terminals: Term & Fixed. Fixed is same as Term but without ligatures.
  --   in the long run, I'd like to have a keybinding to enable/disable ligatures on demand,
  --   by switching font for example.
  --   --> for now, use Term (with ligatures)
  --
  -- + Has 2 additional variants for horizontal size: Normal & Extended. The Normal is the one
  --   which does not mention 'Extended'. Extended is wider than Normal.
  --   --> use Extended variant, the normal one is way too thin!!!
  local font = font_with_fallback("Iosevka Term Extended")
  local font_rules = nil
  -- It finds automatically all the required fonts, no need to specify all the variants!
  return font, font_rules
end

local function font_and_rules_for_jetbrains()
  -- Use a _very slightly_ lighter variant, so that regular bold really stand out
  local font = font_with_fallback("JetBrains Mono Light")
  local font_rules = {
    {
      italic = true,
      font = font_with_fallback("JetBrains Mono Light Italic"),
    },
    {
      italic = true, intensity = "Bold",
      font = font_with_fallback("JetBrains Mono Bold Italic"),
    },
    {
      intensity = "Bold",
      font = font_with_fallback("JetBrains Mono Bold"),
    },
  }
  return font, font_rules
end

local function font_and_rules_for_cascadia()
  local font = font_with_fallback("Cascadia Code")
  -- local font = font_with_fallback("Cascadia Code Light")
  local font_rules = {
    -- NOTE: There is no Italic in font Cascadia...
    {
      italic = true,
      font = font_with_fallback("JetBrains Mono Italic"),
    },
    {
      italic = true, intensity = "Bold",
      font = font_with_fallback("JetBrains Mono Bold Italic"),
    },
    {
      intensity = "Bold",
      -- font = font_with_fallback("JetBrains Mono Bold"),
      font = font_with_fallback("Cascadia Code Bold"),
    },
  }
  return font, font_rules
end

-- FIXME (<- this is an example of bolded text)
-- 0 1 2 3 4 5 6 7 8 9
-- Some ligatures: != <-> <-  -> ----> => ==> ===> -- --- /../;;/ #{}
--  <> <!-- --> ->> --> <= >= ++ == === := a::b::c a&&b a||b

cfg.font, cfg.font_rules = font_and_rules_for_jetbrains()
-- cfg.font, cfg.font_rules = font_and_rules_for_cascadia()
-- cfg.font, cfg.font_rules = font_and_rules_for_iosevka()

-- Enable various OpenType features
-- See https://docs.microsoft.com/en-us/typography/opentype/spec/featurelist
cfg.harfbuzz_features = {
  "zero", -- Use a slashed zero '0' (instead of dotted)
  "kern", -- (default) kerning (todo check what is really is)
  "liga", -- (default) ligatures
  "clig", -- (default) contextual ligatures
}

return cfg
