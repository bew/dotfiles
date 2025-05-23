local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
---@diagnostic disable-next-line unused-local (it's useful for debugs)
local _f = U.fmt.str_space_concat

local _U = {}

---@param value string?
---@return boolean
function _U.is_and_has_text(value)
  return type(value) == "string" and value ~= ""
end

---@param unicode_variant string
---@param ascii_variant string
---@return string
function _U.unicode_or(unicode_variant, ascii_variant)
  if not _U.is_and_has_text(vim.env.ASCII_ONLY) then
    return unicode_variant
  else
    return ascii_variant
  end
end

---@param maybe_txt string
---@param default string
---@return string
function _U.some_text_or(maybe_txt, default)
  -- small helper to avoid checking nil or empty string
  if _U.is_and_has_text(maybe_txt) then
    return maybe_txt
  else
    return default
  end
end

---@param spec {active_ctermbg: integer, inactive_ctermbg: integer}
---@return table
function _U.white_with_bg(spec)
  if hline_conditions.is_active() then
    return { ctermbg = spec.active_ctermbg, ctermfg = 255, cterm = {bold = true} }
  else
    return { ctermbg = spec.inactive_ctermbg, ctermfg = 252, cterm = {bold = true} }
  end
end

--- Returns a function that executes the given callback in the context of the clicked window
---@param callback fun(winid: integer)
---@return fun()
function _U.on_click_in_win_context(callback)
  return function()
    local winid = vim.fn.getmousepos().winid
    -- In the context of the clicked window
    vim.api.nvim_win_call(winid, function()
      callback(winid)
    end)
  end
end

_U.SPACE = { provider = " " }
_U.__WIDE_SPACE__ = { provider = "%=" }

return _U
