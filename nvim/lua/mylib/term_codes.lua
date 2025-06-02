--[[
-- Inspired from `multicursor-nvim`, by @jake-stewart ✨
--]]

--- @class mylib.TermCode: {[string]: string}
local TERM_CODES = {}
local mt = {}

--- When using TERM_CODES.foobar, return the internal representation of <foobar>,
--- with support for full modifier names.
---@param given_key string
---@return string
function mt.__index(self, given_key)
    local key = given_key:lower()
        :gsub("ctrl_", "c-")
        :gsub("meta_", "m-")
        :gsub("alt_", "a-")
        :gsub("shift_", "s-")
        :gsub("os_", "d-")
        :gsub("_", "-")
    self[given_key] = TERM_CODES.replace("<" .. key .. ">")
    return self[given_key]
end

--- Replace term codes for given keys
---@param keys string
---@return string
function TERM_CODES.replace(keys)
  return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

return setmetatable(TERM_CODES, mt)
