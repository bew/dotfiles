if vim.o.buftype ~= "help" then
  -- We're probably editing a help file, we don't want these helpers when
  -- writing one!
  return
end

local K = require"mylib.keymap_system"

-- Fast quit
K.toplevel_buf_map{mode="n", key="q", action=my_actions.close_win_back_to_last}
-- Backup for macro recording
K.toplevel_buf_map{mode="n", key=[[<M-q>]], action="q"}

-- Fast more help
K.toplevel_buf_map{mode="n", key=[[<M-h>]], action=":h "}

-- Fast vertical movement
K.toplevel_buf_map{mode="n", key="J", action=[[<C-d>]]}
K.toplevel_buf_map{mode="n", key="K", action=[[<C-u>]]}

-- Go to help hyper link
K.toplevel_buf_map{mode="n", key="o",    action=[[<C-]>]]}
K.toplevel_buf_map{mode="n", key="<CR>", action=[[<C-]>]]}

--- Jump to next/prev link after/before cursor, wrapping around if needed
---@param dir "next"|"prev"
local function jump_to_link(dir)
  local tree = vim.treesitter.get_parser():parse()[1]
  local link_query = vim.treesitter.query.parse("vimdoc", [[
    [
      (optionlink)
      (taglink)
    ] @link
  ]])

  local cursor_row1, cursor_col0 = unpack(vim.api.nvim_win_get_cursor(0))
  local cursor_row0 = cursor_row1 - 1 -- Convert to 0-indexed

  local target_node
  for _id, node in link_query:iter_captures(tree:root(), 0) do
    local start_row0, start_col0, end_row0, end_col0 = node:range()
    if dir == "next" then
      if (start_row0 > cursor_row0 or (start_row0 == cursor_row0 and start_col0 > cursor_col0)) then
        target_node = node
        break
      end
    elseif dir == "prev" then
      if (end_row0 < cursor_row0 or (end_row0 == cursor_row0 and end_col0 < cursor_col0)) then
        target_node = node
      end
    end
  end

  -- If no target node is found, wrap around
  if not target_node then
    vim.notify("No links there, wrapped around")
    for _id, node in link_query:iter_captures(tree:root(), 0) do
      if dir == "next" then
        target_node = node
        break
      elseif dir == "prev" then
        target_node = node
      end
    end
  end

  if target_node then
    local node_row0, node_col0 = target_node:range()
    vim.api.nvim_win_set_cursor(0, {node_row0 + 1, node_col0})
  else
    vim.notify("No links found 🤔", vim.log.levels.INFO)
  end
end

K.toplevel_buf_map{mode="n", key=[[<C-n>]], action=function()
  jump_to_link("next")
end}
K.toplevel_buf_map{mode="n", key=[[<C-p>]], action=function()
  jump_to_link("prev")
end}

-- Set statusline comment for this buffer
vim.b.bew_statusline_comment = "o: open | C-n/p: find link | M-h: :h"
