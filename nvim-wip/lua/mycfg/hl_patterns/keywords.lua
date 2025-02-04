
local U = require"mylib.utils"
local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.Pattern}
local patterns = {}

--- Give keyword variants for FOO:
--- - `FOO`
--- - `FOO:`
local function _big_word_variants(big_word)
  return {
    _U.keywordize(big_word),
    _U.keywordize(big_word .. ":"),
  }
end

------- Group: General keywords

patterns.big_todo = {
  pattern = _big_word_variants"TODO",
  group = _U.define_hl("big_todo", {
    ctermfg = 11,
    bold = true,
  }),
}

patterns.big_note = {
  pattern = _big_word_variants"NOTE",
  group = _U.define_hl("big_note", {
    ctermfg = 32,
    underline = true,
  }),
}

patterns.small_note = {
  pattern = "note:",
  group = _U.define_hl("small_note", {
    ctermfg = 32,
  }),
}

patterns.big_fixme = {
  pattern = _big_word_variants"FIXME",
  group = _U.define_hl("big_fixme", {
    ctermfg = 160,
    underline = true,
    bold = true,
  }),
}

patterns.big_idea = {
  pattern = _big_word_variants"IDEA",
  group = _U.define_hl("big_idea", {
    ctermfg = 128,
    bold = true,
  }),
}

patterns.big_maybe = {
  pattern = _big_word_variants"MAYBE",
  group = _U.define_hl("big_maybe", {
    ctermfg = 128,
    bold = true,
  }),
}

patterns.big_fail_bad = {
  pattern = U.concat_lists {
    _big_word_variants"FAIL",
    _big_word_variants"BAD",
  },
  group = _U.define_hl("big_fail_bad", {
    ctermfg = 124,
    bold = true,
  }),
}

patterns.big_warning = {
  pattern = U.concat_lists {
    _big_word_variants"WARN",
    _big_word_variants"WARNING",
  },
  group = _U.define_hl("big_warning", {
    ctermfg = 11,
    italic = true,
  }),
}

------- Group: General symbols

patterns.sym_question = {
  -- note: Match `BLA(?)`
  pattern = "%(%?%)",
  group = _U.define_hl("sym_question", {
    ctermfg = 128,
    bold = true,
  }),
}

patterns.sym_warn = {
  -- note: Match `BLA /!\`
  pattern = "/!\\",
  group = _U.define_hl("sym_warn", {
    ctermfg = 11,
    bold = true,
    underline = true,
  }),
}

patterns.sym_excl = {
  -- note: Match `BLA(!!)`
  pattern = "%(!!%)",
  group = _U.define_hl("sym_excl", {
    ctermfg = 124,
    bold = true,
  }),
}

------- Group: Misc keywords


patterns.misc_big_words = {
  pattern = {
    _U.keywordize"DOC:",
    _U.keywordize"REF:",
    _U.keywordize"RELATED:",
    _U.keywordize"SEE:",
    _U.keywordize"TOTRY:",
  },
  group = _U.define_hl("misc_big_words", {
    ctermfg = 255,
    bold = true,
  }),
}

patterns.faq = {
  pattern = _big_word_variants"FAQ",
  group = _U.define_hl("faq", {
    ctermfg = 129,
    bold = true,
  }),
}

patterns.QnA_Q = {
  pattern = _U.keywordize"Q:",
  group = _U.define_hl("QnA_Q", {
    ctermfg = 202,
    bold = true,
  })
}
patterns.QnA_A = {
  pattern = _U.keywordize"A:",
  group = _U.define_hl("QnA_A", {
    ctermfg = 34,
    bold = true,
  })
}

return patterns
