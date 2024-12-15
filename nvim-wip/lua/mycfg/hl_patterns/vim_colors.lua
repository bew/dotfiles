local _U = require"mycfg.hl_patterns.utils"

local patterns = {}

patterns.cterm_color = {
  -- note: Matches:
  -- - `ctermfg=42`
  -- - `ctermfg = 42`
  pattern = {
    "ctermfg=%d+",
    "ctermfg = %d+",
    "ctermbg=%d+",
    "ctermbg = %d+",
  },
  group = "", -- no highlight, only extmark
  extmark_opts = function(_, match)
    local color = match:match "%d+$" -- find color ID at the end
    local hl_group = _U.define_hl("term"..color, {
      ctermfg = tonumber(color),
    })
    return {
      hl_mode = "combine", -- combine with bg color
      virt_text = { { "⬤ ", hl_group } },
      virt_text_pos = "eol",
    }
  end,
}

return patterns
