local K = require"mylib.keymap_system"

-- Fast quit
K.toplevel_buf_map{mode="n", key="q", action=my_actions.close_win_back_to_last}
-- Backup for macro recording
K.toplevel_buf_map{mode="n", key=[[<C-M-q>]], desc="Record macro", action="q"}

-- Scroll line by line
K.toplevel_buf_map{mode="n", key="j", desc="Scroll down (slow)", action=[[<C-e>]]}
K.toplevel_buf_map{mode="n", key="k", desc="Scroll up (slow)",   action=[[<C-y>]]}

-- Scroll half-screen by half-screen
K.toplevel_buf_map{mode="n", key="J", desc="Scroll down (fast)", action=[[<C-d>]]}
K.toplevel_buf_map{mode="n", key="K", desc="Scroll up (fast)",   action=[[<C-u>]]}

-- Backup for cursor up/down (can help with manual selections)
K.toplevel_buf_map{mode="n", key=[[<M-j>]], action=[[<Down>]]}
K.toplevel_buf_map{mode="n", key=[[<M-k>]], action=[[<Up>]]}


-- Follow man page link
K.toplevel_buf_map{mode="n", key=[[o]],             desc="Go to man link", action=vim.cmd.Man}
K.toplevel_buf_map{mode="n", key=[[<2-LeftMouse>]], desc="Go to man link", action=vim.cmd.Man}

-- Open new man page
K.toplevel_buf_map{mode="n", key=[[<M-o>]], desc="Quick open man page", action=":Man "}

--- Jump to next/prev Manpage link after/before cursor, wrapping around if needed
---@param dir "next"|"prev"
local function jump_to_manpage(dir)
  local flags = "wz" -- w: wrap at eof | z: from cursor column not 0
  if dir == "prev" then
    flags = flags .. "b" -- b: search backward
  end
  -- The Manpage links format is: `foobar(42)`
  local pos = vim.fn.searchpos([[\C[a-z][a-z0-9-]\+(\d)]], flags)
  vim.fn.cursor(pos)
end
K.toplevel_buf_map{mode="n", key=[[<C-n>]], desc="Jump to next manpage link", action=function() jump_to_manpage("next") end}
K.toplevel_buf_map{mode="n", key=[[<C-p>]], desc="Jump to prev manpage link", action=function() jump_to_manpage("prev") end}

vim.b.bew_statusline_comment = "2-clicks/o: open at cursor | M-o: open new | C-n/p: find link"
