local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

-- e.g. Or this thing (?)
patterns.sym_question = {
  pattern = "%(%?%)",
  group = _U.define_hl("sym_question", {
    ctermfg = 128,
    bold = true,
  }),
}

-- e.g. /!\ This is a warning!
patterns.sym_warn = {
  pattern = "/!\\",
  group = _U.define_hl("sym_warn", {
    ctermfg = 11,
    bold = true,
    underline = true,
    nocombine = true, -- nicer render when it's not italic (this opt ensures that)
  }),
}

-- e.g. Crazy stuff(!!)
patterns.sym_excl = {
  pattern = "%(!!%)",
  group = _U.define_hl("sym_excl", {
    ctermfg = 124,
    bold = true,
  }),
}

-- e.g. oh yeah <3
-- e.g. (or in a note <3)
-- But not `<3.0` nor `1<<3`
patterns.sym_heart = {
  pattern = {
    "^()<3()$", -- alone on a line
    "^()<3()[^%.]", -- at line start, not followed by `.`
    "[^<]()<3()$", -- at line end, not preceded by <
    "[^<]()<3()[^%.]", -- inline, not preceded by <, not followed by `.`
  },
  group = _U.define_hl("sym_heart", {
    ctermfg = 204,
    bold = true,
  }),
}

return patterns
