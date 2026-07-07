local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

-- e.g.
-- - 20251117T1742
patterns.b2_id = {
  pattern = {
    "%d%d%d%d%d%d%d%dT%d%d%d%d", -- brain ID
  },
  group = _U.define_hl("b2_id", {
    ctermfg = 147,
  }),
}
patterns.b2_id_T = {
  pattern = {
    "%d%d%d%d%d%d%d%d()T()%d%d%d%d", -- brain ID
  },
  group = _U.define_hl("b2_id_T", {
    ctermfg = 153,
    bold = true,
  }),
}

-- e.g.
-- - @2025-11-17
-- - @2026-06
patterns.b2_dates = {
  pattern = {
    "@()%d%d%d%d%-%d%d%-%d%d()", -- @date (year-month-day)
    "@()%d%d%d%d%-%d%d()", -- @dat (year-month)
  },
  group = _U.define_hl("b2_dates", {
    ctermfg = 32, -- (like 'note:')
    italic = true,
  }),
}
patterns.b2_dates_at_sym = {
  pattern = {
    "()@()%d%d%d%d%-%d%d%-%d%d", -- @ symbol for @date (year-month-day)
    "()@()%d%d%d%d%-%d%d", -- @ symbol for @dat (year-month)
  },
  group = _U.define_hl("b2_dates_at_sym", {
    ctermfg = 39,
    bold = true,
  }),
}

-- e.g.
-- - <FOO-bar:Blabl@Bla>
-- - <med1a:"rest of data">
-- - <brain:20251117T1744#someid>
--
-- But does NOT match
-- - <https://foo> or <file:///bla/bla/more/bla> (uri)
-- - <23:> (doesn't start with letter..)
-- - <T: Random> (rust!)
-- - foo::<bar::baz>
patterns.b2_custom_links = {
  pattern = [[<()[A-Za-z][A-Za-z0-9-]*():[^:>/ ][^>]->]],
  group = _U.define_hl("b2_custom_links", {
    italic = true,
    underline = true,
  }),
}

return patterns
