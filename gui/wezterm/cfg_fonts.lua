local wezterm = require "wezterm"

local cfg = {}

-- Disable annoying default behaviors
cfg.adjust_window_size_when_changing_font_size = false
-- that one was opening a separate win on first unknown glyph, stealing windows focus (!!)
cfg.warn_about_missing_glyphs = false

cfg.font_size = 13.0

-- Makes FontAwesome's double-width glyphs display properly!
cfg.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"

-- Additional font directory (necessary to find FontAwesome font!)
cfg.font_dirs = {"fonts"} -- relative to main config file

local function font_with_fallback(font_spec)
  -- family names, not file names
  return wezterm.font_with_fallback({
    font_spec,
    -- Nice emoji font from Microsoft ✨
    -- (TTF files can be downloaded from <https://github.com/tetunori/fluent-emoji-webfont>)
    -- (Read more at <brain2:20220604T2030#fluent-emoji>)
    "Fluent Emoji Color",
    "Font Awesome 6 Free Solid", -- nice double-spaced symbols!
  })
end

local function setup_jetbrains_font()
  cfg.font = font_with_fallback({family="JetBrains Mono", weight="Regular"})
  -- note: Using ExtraBold for bold text, to better show the difference between normal & bold text
  -- note: Using Light for normal text (and Bold for bold text) is too thin and doesn't
  --   render/antialias very well on MacOS..
  cfg.font_rules = {
    {
      intensity = "Normal",
      italic = true,
      font = font_with_fallback({family="JetBrains Mono", weight="Regular", italic=true}),
    },
    {
      intensity = "Bold",
      italic = true,
      font = font_with_fallback({family="JetBrains Mono", weight="ExtraBold", italic=true}),
    },
    {
      intensity = "Bold",
      font = font_with_fallback({family="JetBrains Mono", weight="ExtraBold"}),
    },
  }
end

-- FIXME (<- this is an example of bolded text)
-- 0 1 2 3 4 5 6 7 8 9
-- Some ligatures: != <-> <-  -> ----> => ==> ===> -- --- /../;;/ #{}
--  <> <!-- --> ->> --> <= >= ++ == === := a::b::c a&&b a||b
--
-- Some emojis: ☹️ 🔎 😇 🤷 🙃 🖐 ❤️⚠️ ✨ 👋

setup_jetbrains_font()
cfg.unicode_version = 15

cfg.strikethrough_position = "0.555cell"

-- Right so that the underline touches the cell below
cfg.underline_position = "-0.14cell"
-- /!\ Cannot change underline thickness without changing the stroke size of custom glyphs
--   (note: I'm working on a PR..)
-- cfg.underline_thickness = "0.1cell"

-- Enable various OpenType features
-- See https://docs.microsoft.com/en-us/typography/opentype/spec/featurelist
cfg.harfbuzz_features = {
  "zero", -- Use a slashed zero '0' (instead of dotted)
  "kern", -- (default) kerning (todo check what is really is)
  "liga", -- (default) ligatures
  "clig", -- (default) contextual ligatures
}

return cfg
