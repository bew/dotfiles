
local U = require"mylib.utils"
local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
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

-- FIXME: groups are NOT re-created after a colorscheme is applied
-- (IDEA: replace all group defs with function that DO the def, will be re-run on colorscheme change)
-- (IDEA: in `define_hl`, register that hl in a global table that get's re-applied 🤔)

------- Group: General keywords

patterns.big_todo = {
  pattern = _big_word_variants"TODO",
  group = _U.define_hl("big_todo", {
    ctermfg = 11,
    bold = true,
  }),
}

patterns.small_todo = {
  pattern = _big_word_variants"todo",
  group = _U.define_hl("small_todo", {
    ctermfg = 178,
  }),
}

-- e.g. NOTE: an important note!
patterns.big_note = {
  pattern = _big_word_variants"NOTE",
  group = _U.define_hl("big_note", {
    ctermfg = 32,
    underline = true,
  }),
}

-- e.g. note: a small note..
patterns.small_note = {
  pattern = _U.keywordize"note:",
  group = _U.define_hl("small_note", {
    ctermfg = 32,
  }),
}

patterns.big_fixme = {
  pattern = U.concat_lists {
    _big_word_variants"FIXME",
    _big_word_variants"TMP!",
    {
      "%(%?%?%)", -- (??)
    },
  },
  group = _U.define_hl("big_fixme", {
    ctermfg = 160,
    underdashed = true,
    bold = true,
  }),
}

-- e.g. MAYBE this thing is a good IDEA?
patterns.big_idea = {
  pattern = U.concat_lists {
    _big_word_variants"IDEA",
    _big_word_variants"MAYBE",
  },
  group = _U.define_hl("big_idea", {
    ctermfg = 128,
    bold = true,
    underdotted = true,
  }),
}
patterns.small_idea = {
  pattern = _U.keywordize"idea:",
  group = _U.define_hl("small_idea", {
    ctermfg = 134,
    underdotted = true,
  }),
}

patterns.big_fail_bad = {
  pattern = U.concat_lists {
    _big_word_variants"FAIL",
    _big_word_variants"BAD",
    _big_word_variants"BAD%+%+", -- BAD++
    _big_word_variants"BLOCKED",
    _big_word_variants"BLOCKER",
    _big_word_variants"PROBLEM",
    _big_word_variants"MISSING",
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
    {
      _U.keywordize"warn:",
    },
  },
  group = _U.define_hl("big_warning", {
    ctermfg = 11,
    italic = true,
  }),
}

patterns.big_tbd = {
  pattern = {
    _U.keywordize"TBD:",
    _U.keywordize"TO BE DEFINED:",
  },
  group = _U.define_hl("big_tbd", {
    ctermfg = 162,
    bold = true,
  }),
}

-- e.g. GOAL: get some RESULTs..
patterns.big_goal = {
  pattern = U.concat_lists {
    _big_word_variants"GOAL",
    _big_word_variants"RESULT",
    _big_word_variants"RESULTS",
    _big_word_variants"RESULTs",
    {
      _U.keywordize"goal:",
      _U.keywordize"results?:",
    },
  },
  group = _U.define_hl("big_goal", {
    ctermfg = 202,
    bold = true,
  }),
}

-- e.g. Start with WHY 🤔
patterns.big_why = {
  pattern = U.concat_lists {
    _big_word_variants"WHY",
    {
      _U.keywordize"safe:", -- safe because...
    },
  },
  group = _U.define_hl("big_why", {
    ctermfg = 202,
  }),
}

------- Group: Tech usage notes keywords

patterns.big_good = {
  pattern = U.concat_lists {
    _big_word_variants"GOOD",
    _big_word_variants"NICE",
    {
      _U.keywordize"good:",
      _U.keywordize"nice:",
    },
  },
  group = _U.define_hl("big_good", {
    ctermfg = 34,
  }),
}

-- e.g. GRR, MEH, WEIRD, WTF, WHYY??
patterns.big_grr_wat = {
  pattern = U.concat_lists {
    _big_word_variants"GRR",
    _big_word_variants"MEH",
    _big_word_variants"WEIRD",
    _big_word_variants"WTF",
    _big_word_variants"WHYY%?%?",
  },
  group = _U.define_hl("big_grr_wat", {
    ctermfg = 166,
  }),
}

-- e.g. GOTCHA, FIXED
patterns.big_gotcha = {
  pattern = U.concat_lists {
    _big_word_variants"GOTCHA",
    _big_word_variants"FIXED",
  },
  group = _U.define_hl("big_gotcha", {
    ctermfg = 32,
    bold = true,
  }),
}

-- e.g. HINT, SEE, RELATED, USAGE, TRACKING-ISSUE, ISSUE
patterns.big_hint_usage_tracking = {
  pattern = U.concat_lists {
    _big_word_variants"HINT",
    _big_word_variants"SEE",
    _big_word_variants"RELATED",
    _big_word_variants"USAGE",
    _big_word_variants"TRACKING%-ISSUE",
    _big_word_variants"ISSUE",
    {
      _U.keywordize"hint:",
      _U.keywordize"see:",
    },
  },
  group = _U.define_hl("big_hint_usage_tracking", {
    ctermfg = 36,
  }),
}

-- note: TICKET != ISSUE:
-- - TICKET is something I made for work, which I will be working on
-- - ISSUE is a tracking info, potentially out of my control
patterns.misc_ticket = {
  pattern = _big_word_variants"TICKET",
  group = _U.define_hl("misc_ticket", {
    ctermfg = 166,
  }),
}

-- e.g. ESTIMATION
patterns.misc_estimation = {
  pattern = _big_word_variants"ESTIMATION",
  group = _U.define_hl("misc_estimation", {
    ctermfg = 173,
    bold = true,
  }),
}

------- Group: General symbols

-- e.g. Or this thing(?)
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
-- But not `<3.0`
patterns.sym_heart = {
  pattern = {
    "()<3()$",
    "()<3()[^%.]",
  },
  group = _U.define_hl("sym_heart", {
    ctermfg = 204,
    bold = true,
  }),
}

------- Group: Misc keywords

patterns.misc_light_words = {
  pattern = U.concat_lists {
    _big_word_variants"DEBUG",
    _big_word_variants"HACK",
    _big_word_variants"WANT",
    _big_word_variants"REF",
    _big_word_variants"REFs",
    {
      _U.keywordize"tmp:",
    },
  },
  group = _U.define_hl("misc_light_words", {
    ctermfg = 253,
  }),
}

-- e.g. (ref: this is a light ref)
patterns.misc_lighter_words = {
  pattern = U.concat_lists {
    {
      _U.keywordize"ref:",
      _U.keywordize"refs:",
    },
    _big_word_variants"EXAMPLE",
    _big_word_variants"EXAMPLES",
    _big_word_variants"Example",
  },
  group = _U.define_hl("misc_lighter_words", {
    ctermfg = 249,
  }),
}

local function heavy_word_variants(word)
  return U.concat_lists {
    _big_word_variants(word),
    -- This one is useful to make kind of sections of that word
    { "%[" .. word .. "%]:?" },
  }
end
-- e.g. WIP [TOTRY]
patterns.misc_heavy_words = {
  pattern = U.concat_lists {
    heavy_word_variants"DOC",
    heavy_word_variants"TOTRY",
    heavy_word_variants"TOTHINK",
    heavy_word_variants"TOCHECK",
    heavy_word_variants"IMPORTANT",
    heavy_word_variants"ASK",
    heavy_word_variants"FEEDBACK",
    heavy_word_variants"WIP",
    heavy_word_variants"EXPERIMENT",
    -- note: TMP != TMP! (`tmp!` has short lifespan; tmp potentially has no end date 😬)
    heavy_word_variants"TMP:",
  },
  group = _U.define_hl("misc_big_words", {
    ctermfg = 253,
    bold = true,
  }),
}

patterns.misc_done = {
  pattern = U.concat_lists {
    _big_word_variants"DONE",
    _big_word_variants"SOLUTION",
    _big_word_variants"SOLUTIONS",
    {
      _U.keywordize"done:",
      _U.keywordize"solution:",
      _U.keywordize"solutions:",
    },
  },
  group = _U.define_hl("misc_done", {
    ctermfg = 34,
  }),
}

patterns.misc_tldr = {
  pattern = U.concat_lists {
    _big_word_variants"TL;DR",
    _big_word_variants"tl;dr",
  },
  group = _U.define_hl("misc_tldr", {
    ctermfg = 45,
    bold = true,
  }),
}

patterns.misc_meta = {
  pattern = _big_word_variants"META",
  group = _U.define_hl("misc_meta", {
    ctermfg = 99,
    bold = true,
    underdashed = true,
  }),
}

-- e.g. <- example!
patterns.misc_e_g = {
  pattern = _big_word_variants"e%.g%.",
  group = _U.define_hl("misc_e_g", {
    ctermfg = 105,
  }),
}

patterns.misc_faq = {
  pattern = _big_word_variants"FAQ",
  group = _U.define_hl("faq", {
    ctermfg = 128,
    bold = true,
  }),
}

patterns.misc_QnA_Q = {
  pattern = _U.keywordize"Q:",
  group = _U.define_hl("QnA_Q", {
    ctermfg = 202,
    bold = true,
  })
}
patterns.misc_QnA_A = {
  pattern = _U.keywordize"A:",
  group = _U.define_hl("QnA_A", {
    ctermfg = 34,
    bold = true,
  })
}

return patterns
