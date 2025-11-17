local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

-- e.g.
-- - 20251117T1742
-- - @2025-11-17
-- TODO: find a nice way to distinguish the different part of the date/brainID 🤔
patterns.b2_id = {
  pattern = {
    "%d%d%d%d%d%d%d%dT%d%d%d%d", -- brain ID
    "@%d%d%d%d%-%d%d%-%d%d", -- @date
  },
  group = _U.define_hl("b2_id", {
    ctermfg = 140,
    italic = true,
  }),
}

-- e.g.
-- - <FOO-bar:Blabl@Bla>
-- - <med1a:"rest of data">
-- - <brain:20251117T1744#someid>
--
-- But does NOT match
-- - <https://foo> or <file:///bla> (url)
-- - <23:> (doesn't start with letter..)
-- - <T: Random> (rust!)
patterns.b2_custom_links = {
  pattern = [[<()[A-Za-z][A-Za-z0-9-]*():[^>/ ][^>]->]],
  group = _U.define_hl("b2_custom_links", {
    italic = true,
    underline = true,
  }),
}

return patterns
