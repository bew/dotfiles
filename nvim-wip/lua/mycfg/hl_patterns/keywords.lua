
local U = require"mycfg.hl_patterns.utils"

local patterns = {}

------- Group: General keywords

patterns.big_todo = {
  pattern = {
    U.keywordize"TODO",
    U.keywordize"TODO:",
  },
  group = U.define_hl("big_todo", {
    ctermfg = 11,
    bold = true,
  }),
}

patterns.big_note = {
  pattern = {
    U.keywordize"NOTE",
    U.keywordize"NOTE:",
  },
  group = U.define_hl("big_note", {
    ctermfg = 32,
    underline = true,
  }),
}

patterns.big_fixme = {
  pattern = {
    U.keywordize"FIXME",
    U.keywordize"FIXME:",
  },
  group = U.define_hl("big_fixme", {
    ctermfg = 160,
    underline = true,
    bold = true,
  }),
}

patterns.big_idea = {
  pattern = {
    U.keywordize"IDEA",
    U.keywordize"IDEA:",
  },
  group = U.define_hl("big_idea", {
    ctermfg = 128,
    bold = true,
  }),
}

patterns.big_maybe = {
  pattern = {
    U.keywordize"MAYBE",
    U.keywordize"MAYBE:",
  },
  group = U.define_hl("big_maybe", {
    ctermfg = 128,
    bold = true,
  }),
}

patterns.big_fail = {
  pattern = {
    U.keywordize"FAIL",
    U.keywordize"FAIL:",
  },
  group = U.define_hl("big_fixme", {
    ctermfg = 124,
    bold = true,
  }),
}

------- Group: General symbols

patterns.sym_question = {
  -- note: Match `BLA(?)`
  pattern = "%(%?%)",
  group = U.define_hl("sym_question", {
    ctermfg = 128,
    bold = true,
  }),
}

------- Group: Misc keywords

local default_hl = U.define_hl("default", {
  ctermfg = 255,
  bold = true,
})

patterns.misc_keywords = {
  pattern = {
    U.keywordize"DOC:",
    U.keywordize"REF:",
    U.keywordize"RELATED:",
    U.keywordize"SEE:",
    U.keywordize"TOTRY:",
  },
  group = default_hl,
}

patterns.faq = {
  pattern = {
    U.keywordize"FAQ",
    U.keywordize"FAQ:",
  },
  group = U.define_hl("faq", {
    ctermfg = 129,
    bold = true,
  }),
}

patterns.QnA_Q = {
  pattern = U.keywordize"Q:",
  group = U.define_hl("QnA_Q", {
    ctermfg = 202,
    bold = true,
  })
}
patterns.QnA_A = {
  pattern = U.keywordize"A:",
  group = U.define_hl("QnA_A", {
    ctermfg = 34,
    bold = true,
  })
}

return patterns
