local hline_conditions = require"heirline.conditions"

local libU = require"mylib.utils"
local _f = libU.str_space_concat ---@diagnostic disable unused-local

local U = {}

---@param value string?
---@return boolean
function U.is_and_has_text(value)
  return type(value) == "string" and value ~= ""
end

---@param unicode_variant string
---@param ascii_variant string
---@return string
function U.unicode_or(unicode_variant, ascii_variant)
  if not U.is_and_has_text(vim.env.ASCII_ONLY) then
    return unicode_variant
  else
    return ascii_variant
  end
end

---@param maybe_txt string
---@param default string
---@return string
function U.some_text_or(maybe_txt, default)
  -- small helper to avoid checking nil or empty string
  if U.is_and_has_text(maybe_txt) then
    return maybe_txt
  else
    return default
  end
end

---@param spec {active_ctermbg: integer, inactive_ctermbg: integer}
---@return table
function U.white_with_bg(spec)
  if hline_conditions.is_active() then
    return { ctermbg = spec.active_ctermbg, ctermfg = 255, cterm = {bold = true} }
  else
    return { ctermbg = spec.inactive_ctermbg, ctermfg = 252, cterm = {bold = true} }
  end
end

--- Returns a function that executes the given callback in the context of the clicked window
---@param callback fun(winid: integer)
---@return fun()
function U.on_click_in_win_context(callback)
  return function()
    local winid = vim.fn.getmousepos().winid
    -- In the context of the clicked window
    vim.api.nvim_win_call(winid, function()
      callback(winid)
    end)
  end
end

U.SPACE = { provider = " " }
U.__WIDE_SPACE__ = { provider = "%=" }

return U
