local K = require"mylib.keymap_system"
local U = require"mylib.utils"

-- I: <Alt-:> to insert a colon after cursor.
K.toplevel_buf_map{mode="i", key=[[<M-:>]], action=[[: <C-g>U<Left><C-g>U<Left>]]}

-- I: <Alt-f> to toggle between `f"..."` and `"..."`
local function fstring_toggle()
  local node = U.ts.try_get_node_at_cursor()
  if not node then return end
  -- Python string nodes looks like:
  -- (string
  --   (string_start)
  --   (string_content)
  --   (string_end))
  -- So the parent _should_ be the `string` node
  local string_node = node:parent()
  if not string_node or string_node:type() ~= "string" then return end

  local str = vim.treesitter.get_node_text(string_node, 0)
  local start_row0, start_col0 = string_node:start()
  local is_fstring = str:sub(1, 1) == "f"
  if is_fstring then
    -- Remove `f` at node start
    vim.api.nvim_buf_set_text(0, start_row0, start_col0, start_row0, start_col0 +1, {})
  else
    -- Insert `f` at node start
    vim.api.nvim_buf_set_text(0, start_row0, start_col0, start_row0, start_col0, {"f"})
  end
end
K.toplevel_buf_map{mode="i", key=[[<M-f>]], action=fstring_toggle}
