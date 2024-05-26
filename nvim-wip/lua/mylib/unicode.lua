local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

local UC = {}

local SMALLCAPS_CHARS = {
  a = "ᴀ",
  b = "ʙ",
  c = "ᴄ",
  d = "ᴅ",
  e = "ᴇ",
  f = "ꜰ",
  g = "ɢ",
  h = "ʜ",
  i = "ɪ",
  j = "ᴊ",
  k = "ᴋ",
  l = "ʟ",
  m = "ᴍ",
  n = "ɴ",
  o = "ᴏ",
  p = "ᴘ",
  q = "ꞯ",
  r = "ʀ",
  s = "ꜱ",
  t = "ᴛ",
  u = "ᴜ",
  v = "ᴠ",
  w = "ᴡ",
  x = "–",
  y = "ʏ",
  z = "ᴢ",
}

--- Replace text with smallcaps glyphs (unsupported chars will be left as-is)
UC.smallcaps = function(text)
  local result = ""
  for _, c in U.iter_chars(text) do
    if SMALLCAPS_CHARS[c] then
      result = result .. SMALLCAPS_CHARS[c]
    else
      result = result .. c
    end
  end
  return result
end

local SUPERSCRIPT_CHARS = {
  A = "ᴬ", B = "ᴮ", C = "ꟲ", D = "ᴰ", E = "ᴱ", F = "ꟳ", G = "ᴳ", H = "ᴴ", I = "ᴵ", J = "ᴶ", K = "ᴷ", L = "ᴸ", M = "ᴹ", N = "ᴺ", O = "ᴼ", P = "ᴾ", Q = "ꟴ", R = "ᴿ", S = "꟱", T = "ᵀ", U = "ᵁ", V = "ⱽ", W = "ᵂ",
  -- XYZ don't exist.. :/
  -- X = "", Y = "", Z = "",

  a = "ᵃ", b = "ᵇ", c = "ᶜ", d = "ᵈ", e = "ᵉ", f = "ᶠ", g = "ᵍ", h = "ʰ", i = "ⁱ", j = "ʲ", k = "ᵏ", l = "ˡ", m = "ᵐ", n = "ⁿ", o = "ᵒ", p = "ᵖ", q = "𐞥", r = "ʳ", s = "ˢ", t = "ᵗ", u = "ᵘ", v = "ᵛ", w = "ʷ", x = "ˣ", y = "ʸ", z = "ᶻ",

  ["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³", ["4"] = "⁴", ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷", ["8"] = "⁸", ["9"] = "⁹", ["+"] = "⁺",
  ["-"] = "⁻", ["="] = "⁼", ["("] = "⁽", [")"] = "⁾",
}

--- Replace text with superscript glyphs, above font baseline (unsupported chars will error out)
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
  ["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃", ["4"] = "₄", ["5"] = "₅", ["6"] = "₆", ["7"] = "₇", ["8"] = "₈", ["9"] = "₉",
  ["+"] = "₊", ["-"] = "₋", ["="] = "₌", ["("] = "₍", [")"] = "₎",
}

--- Replace text with subscript glyphs, above font baseline (only numbers & unsupported chars will error out)
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
