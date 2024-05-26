local hline_conditions = require"heirline.conditions"

local libU = require"mylib.utils"
local _f = libU.str_space_concat

local U = {}

function U.is_and_has_text(value)
  return type(value) == "string" and value ~= ""
end

function U.unicode_or(unicode_variant, ascii_variant)
  if not U.is_and_has_text(vim.env.ASCII_ONLY) then
    return unicode_variant
  else
    return ascii_variant
  end
end

function U.some_text_or(maybe_txt, default)
  -- small helper to avoid checking nil or empty string
  if U.is_and_has_text(maybe_txt) then
    return maybe_txt
  else
    return default
  end
end

function U.white_with_bg(spec)
  if hline_conditions.is_active() then
    return { ctermbg = spec.active_ctermbg, ctermfg = 255, cterm = {bold = true} }
  else
    return { ctermbg = spec.inactive_ctermbg, ctermfg = 252, cterm = {bold = true} }
  end
end

U.SPACE = { provider = " " }
U.__WIDE_SPACE__ = { provider = "%=" }

return U
