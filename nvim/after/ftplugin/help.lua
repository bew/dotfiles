if vim.o.buftype ~= "help" then
  -- We're probably editing a help file, we don't want these helpers when
  -- writing one!
  return
end

local K = require"mylib.keymap_system"
local U = require"mylib.utils"

-- Fast quit
K.toplevel_buf_map{mode="n", key="q", action=my_actions.close_win_back_to_last}
-- Backup for macro recording
K.toplevel_buf_map{mode="n", key=[[<C-M-q>]], desc="Record macro", action="q"}

-- Fast more help
K.toplevel_buf_map{mode="n", key=[[<M-h>]], desc="Quick open help", action=":h "}

-- Fast vertical movement
K.toplevel_buf_map{mode="n", key="J", desc="Scroll down", action=[[<C-d>]]}
K.toplevel_buf_map{mode="n", key="K", desc="Scroll up",   action=[[<C-u>]]}

-- Go to help hyper link
K.toplevel_buf_map{mode="n", key="o",    desc="Open help link", action=[[<C-]>]]}
K.toplevel_buf_map{mode="n", key="<CR>", desc="Open help link", action=[[<C-]>]]}

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

  local cursor_pos = U.Pos0.from_vimpos"cursor"

  local target_node ---@type TSNode
  for _id, node in link_query:iter_captures(tree:root(), 0) do
    local start_row0, start_col0, end_row0, end_col0 = node:range()
    if dir == "next" then
      local start_pos = U.Pos0.new{row=start_row0, col=start_col0}
      if start_pos:is_after(cursor_pos) then
        target_node = node
        break
      end
    elseif dir == "prev" then
      local end_pos = U.Pos0.new{row=end_row0, col=end_col0}
      if end_pos:is_before(cursor_pos) then
        target_node = node
      else
        break
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

K.toplevel_buf_map{mode="n", key=[[<C-n>]], desc="Jump to next help link", action=function()
  jump_to_link("next")
end}
K.toplevel_buf_map{mode="n", key=[[<C-p>]], desc="Jump to prev help link", action=function()
  jump_to_link("prev")
end}

-- Set statusline comment for this buffer
vim.b.bew_statusline_comment = "o: open | C-n/p: find link | M-h: :h"
