
-- [EXAMPLES]:
--
-- Many example pickers at:
-- https://github.com/nvim-telescope/telescope.nvim/blob/2ffcfc0d93bc/lua/telescope/builtin/__internal.lua
--
-- Many example make entry functions at:
-- https://github.com/nvim-telescope/telescope.nvim/blob/2ffcfc0d93bc/lua/telescope/make_entry.lua

local tel_builtins = require"telescope.builtin"
local tel_entry_display = require "telescope.pickers.entry_display"
-- local tel_utils = require "telescope.utils"

local U = require"mylib.utils"

---@alias telescope.EntryHighlight [ [number, number], string ] Text highlights in format `{ { start_col, end_col }, hl_group }`

---@class telescope.Entry
---@field value any
---@field valid? boolean If false, the entry won't be displayed in the picker
---@field ordinal string Text used for filtering
---@field display string|(fun(entry: telescope.Entry): string, telescope.EntryHighlight) Text displayed in the picker
---@field filename? string Interpreted by the default action as 'open this file'
---@field bufnr? number Interpreted by the default action as 'open this buffer'
---@field lnum? number Interpreted by the default action as a 'jump to this line'
---@field col? number Interpreted by the default action as a 'jump to this column'


local M = {}

---@param item mylib.QfEntry
---@return string?
local function get_qf_item_filename(item)
  if item.module and item.module ~= "" then
    return item.module
  elseif item.bufnr > 0 then
    local path = vim.api.nvim_buf_get_name(item.bufnr)
    if U.fs.path_exists(path) then
      return path
    end
  end
  return nil
end

---@param opts {max_path_len: number}
local function gen_qf_entry_maker(opts)
  opts = opts or {}

  local displayer = tel_entry_display.create {
    separator = " ┃ ",
    items = {
      { width = opts.max_path_len +4 },
      { width = 4 },
      { remaining = true },
    },
  }

  ---@param entry telescope.Entry
  ---@return string, telescope.EntryHighlight
  local function make_display(entry)
    local filename = entry.filename
    if filename then
      filename = U.fs.simplify_path(filename)
      if filename:len() > opts.max_path_len then
        filename = "…" .. filename:sub(filename:len() - opts.max_path_len - 1)
      end
    end
    return displayer {
      { filename or "", "Directory" },
      { entry.lnum, "@comment" },
      vim.trim(entry.value.text),
    }
  end

  ---@param item mylib.QfEntry
  ---@return telescope.Entry?
  return function(item)
    local filename = get_qf_item_filename(item)

    ---@type telescope.Entry
    return {
      value = item,
      ordinal = (filename or "") .. " " .. item.text,
      display = make_display,

      bufnr = item.bufnr,
      filename = filename or item.text,
      lnum = item.lnum,
      col = item.col,
    }
  end
end

-- Custom qf/loc list picker, with nicer entry display ✨
-- The default is basically all white and doesn't columnize anything..
---@param opts {nr?: number}
M.fancy_quickfix = function(opts)
  opts = opts or {}
  tel_builtins.quickfix {
    nr = opts.nr,
    layout_strategy = "vertical",
    entry_maker = gen_qf_entry_maker { max_path_len = 30 },
  }
end
---@param opts {nr?: number}
M.fancy_loclist = function(opts)
  opts = opts or {}
  tel_builtins.loclist {
    nr = opts.nr,
    layout_strategy = "vertical",
    entry_maker = gen_qf_entry_maker { max_path_len = 30 },
  }
end

return M
