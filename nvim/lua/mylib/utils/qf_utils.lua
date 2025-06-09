local U_qf = {}

---@class mylib.QfEntry: table A nvim {qf,loc}list entry
---@field bufnr number of buffer that has the file name, use bufname() to get the name
---@field module string Module name
---@field lnum number Line number in the buffer (first line is 1)
---@field end_lnum number End of line number if the item is multiline
---@field col number Column number (first column is 1)
---@field end_col number End of column number if the item has range
---@field vcol boolean If true: "col" is visual column; otherwise "col" is byte index
---@field nr number error number
---@field pattern string search pattern used to locate the error
---@field text string Description of the error
---@field type string Type of the error, 'E', '1', etc.
---@field valid boolean Whether the error message was recognized
---@field user_data any Custom data associated with the item

--- Returns whether current buffer is a qf/loc list buffer
---@return boolean
function U_qf.is_qf_buf()
  local ft = vim.o.buftype
  return not not ft:find"quickfix"
end

--- Returns whether current list is a quickfix list (not loclist)
---@return boolean
function U_qf.is_qflist()
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  return wininfo.quickfix == 1 and wininfo.loclist == 0
end

--- Returns whether current list is a location list (not qflist)
---@return boolean
function U_qf.is_loclist()
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  return wininfo.quickfix == 1 and wininfo.loclist == 1
end

---@alias mylib.QfWhichList "qf"|"loc"|"buf"

---@class mylib.QfFunctions
---@field get_info (fun(what?: table): table)
---@field create_new (fun(entries: mylib.QfEntry[], opts?: table): nil)

--- Returns a function to get information about the current list
---@param which_list? mylib.QfWhichList Which type of list (defaults to "buf" but fails if not in qf buffer)
---@return mylib.QfFunctions
function U_qf.get_list_fns(which_list)
  if not which_list or which_list == "buf" then
    if not U_qf.is_qf_buf() then
      error("get_list_info called with ")
    end
    if U_qf.is_qflist() then
      which_list = "qf"
    elseif U_qf.is_loclist() then
      which_list = "loc"
    else
      error("wtf, current win is neither qf nor loc?")
    end
  end

  if which_list == "qf" then
    return {
      get_info = vim.fn.getqflist,
      create_new = function(entries, opts)
        vim.fn.setqflist(entries, " ")
        if opts then
          vim.fn.setqflist({}, "a", opts)
        end
      end,
    }
  else
    return {
      get_info = function(what)
        return vim.fn.getloclist(0, what)
      end,
      create_new = function(entries, opts)
        vim.fn.setloclist(0, entries, " ")
        if opts then
          vim.fn.setloclist(0, {}, "a", opts)
        end
      end,
    }
  end

  -- NOTE for set{qf,loc}list (😬):
  --   If {action} is not present or is set to ' ', then a new list
  --   is created. The new quickfix list is added after the current
  --   quickfix list in the stack and all the following lists are
  --   freed. To add a new quickfix list at the end of the stack,
  --   set "nr" in {what} to "$".
end

--- Returns the list of qf/loc entries
---@param which_list? mylib.QfWhichList See `get_list_info_fn`
---@return mylib.QfEntry[]
function U_qf.get_list_entries(which_list)
  local info_fn = U_qf.get_list_fns(which_list)
  return info_fn.get_info()
end

return U_qf
