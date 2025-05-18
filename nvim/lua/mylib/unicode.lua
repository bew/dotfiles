local U = require"mylib.utils"
local _f = U.fmt.str_space_concat
local _q = U.fmt.str_simple_quote_surround

local UC = {}

local SUPERSCRIPT_CHARS = {
  A = "ᴬ", B = "ᴮ", C = "ꟲ", D = "ᴰ", E = "ᴱ", F = "ꟳ", G = "ᴳ", H = "ᴴ", I = "ᴵ", J = "ᴶ", K = "ᴷ", L = "ᴸ", M = "ᴹ", N = "ᴺ", O = "ᴼ", P = "ᴾ", Q = "ꟴ", R = "ᴿ", S = "꟱", T = "ᵀ", U = "ᵁ", V = "ⱽ", W = "ᵂ",
  -- XYZ don't exist.. :/
  -- X = "", Y = "", Z = "",

  -- Many lowercase letters are missing... h, j, l, r, s, w, x, y
  -- a = "ᵃ", b = "ᵇ", c = "ᶜ", d = "ᵈ", e = "ᵉ", f = "ᶠ", g = "ᵍ", h = "ʰ", i = "ⁱ", j = "ʲ", k = "ᵏ", l = "ˡ", m = "ᵐ", n = "ⁿ", o = "ᵒ", p = "ᵖ", q = "𐞥", r = "ʳ", s = "ˢ", t = "ᵗ", u = "ᵘ", v = "ᵛ", w = "ʷ", x = "ˣ", y = "ʸ", z = "ᶻ",

  -- Numbers
  ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴", ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷", ["8"] = "⁸", ["9"] = "⁹", ["+"] = "⁺",
  -- Few symbols
  ["-"] = "⁻", ["="] = "⁼", ["("] = "⁽", [")"] = "⁾",
}

--- Replace text with superscript glyphs, above font baseline (unsupported chars will error out)
--- (most uppercase letters, numbers & few symbols, unsupported chars will error out)
---@param text string Input text
---@return string
UC.superscript = function(text)
  local result = ""
  for _, c in U.iter_chars(text) do
    if SUPERSCRIPT_CHARS[c] then
      result = result .. SUPERSCRIPT_CHARS[c]
    else
      error(_f("Superscript char", _q(c), "is not supported"))
    end
  end
  return result
end

local SUBSCRIPT_CHARS = {
  -- Numbers
  ["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃", ["4"] = "₄", ["5"] = "₅", ["6"] = "₆", ["7"] = "₇", ["8"] = "₈", ["9"] = "₉",
  -- Few symbols
  ["+"] = "₊", ["-"] = "₋", ["="] = "₌", ["("] = "₍", [")"] = "₎",
}

--- Replace text with subscript glyphs, above font baseline
--- (only numbers & few symbols, unsupported chars will error out)
---@param text string Input text
---@return string
UC.subscript = function(text)
  local result = ""
  for _, c in U.iter_chars(text) do
    if SUBSCRIPT_CHARS[c] then
      result = result .. SUBSCRIPT_CHARS[c]
    else
      error(_f("Subscript char", _q(c), "is not supported"))
    end
  end
  return result
end

return UC
