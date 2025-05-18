local U_visual = {}

local U_fmt = require"mylib.utils.fmt_utils"
local Pos0 = require"mylib.utils.pos_utils".Pos0
local save_run_restore = require"mylib.utils.save_restore_utils".save_run_restore

--- Asserts we are currently in Visual mode, optionally in a specific visual mode kind
---@param goal string Reason why visual mode is needed, for better error msg
---@param restrict_visual_kind? string[] Restrict which kind of visual mode is allowed
---  (defaults to all)
---@return string visual_kind The actual active kind of visual mode
function U_visual.assert_visual_mode(goal, restrict_visual_kind)
  local mode_char_to_visual_kind = {
    ["v"] = "visualchar",
    ["V"] = "visualline",
    [""] = "visualblock",
  }
  if not restrict_visual_kind then
    restrict_visual_kind = vim.tbl_values(mode_char_to_visual_kind)
  end
  local visual_kind = mode_char_to_visual_kind[vim.fn.mode()]
  if not visual_kind then
    -- let's not try to handle cases here, just raise
    error(U_fmt.str_concat("Cannot ", goal, ", not in visual mode"))
  end
  if not vim.tbl_contains(restrict_visual_kind, visual_kind) then
    -- let's not try to handle cases here, just raise
    error(U_fmt.str_space_concat{
      U_fmt.str_concat("Cannot ", goal, ","),
      "not in accepted visual mode: was", visual_kind,
      "but only accepts: ", table.concat(restrict_visual_kind, " or "),
    })
  end
  return visual_kind
end

--- Returns lines of current visual selection
---
--- NOTES:
---   - does NOT preserve Visual mode, ends in Normal mode
---   - preserves cursor position
---
---@return string[]
function U_visual.get_visual_selection_as_lines()
  -- NOTE: Visual selection is a pain to get reliably while handling all cases.
  -- See this PR that attempts to add a vim.get_visual_selection() function:
  --   https://github.com/neovim/neovim/pull/13896
  U_visual.assert_visual_mode("get visual selection")
  -- Register 'v' is used to copy visual selection in (easiest way to get visual selection)
  -- We also save/restore the cursor as yank would move it
  return save_run_restore({ save_registers = {"v"}, save_cursor = true }, function()
    vim.cmd[[noautocmd normal! "vygv]]
    -- NOTE: we switch back to original visual mode after the copy
    -- (we didn't trigger ModeChanged autocmd when moving to normal mode which could be unexpected and give visual artefacts)
    return vim.fn.getreginfo("v").regcontents
  end)
end

--- Get the start & end positions of the current visual selection, must be called from Visual mode.
---@return {start_pos0: mylib.Pos0, end_pos0: mylib.Pos0}
function U_visual.get_visual_start_end_pos0()
  -- limit to visualchar & visualline (don't need for visualblock for now)
  local visual_mode_kind = U_visual.assert_visual_mode("get visual start/end", {"visualchar", "visualline"})

  -- get current cursor pos
  local cursor_pos0 = Pos0.from_vimpos"cursor"
  -- get other side of visual selection
  local other_side_pos0 = Pos0.from_vimpos("pos", "v")

  -- start_pos0 is the top-left corner
  local start_pos0 = Pos0.new{
    row = math.min(cursor_pos0.row, other_side_pos0.row),
    col = math.min(cursor_pos0.col, other_side_pos0.col),
  }
  -- end_pos0 is the bottom-right corner
  local end_pos0 = Pos0.new{
    row = math.max(cursor_pos0.row, other_side_pos0.row),
    col = math.max(cursor_pos0.col, other_side_pos0.col),
  }

  if visual_mode_kind == "visualline" then
    start_pos0.col = 0
    end_pos0.col = vim.v.maxcol
  end
  -- print(U.fmt.str_space_concat{
  --   "visual_mode_kind", vim.inspect(visual_mode_kind),
  --   "cursor_pos0", vim.inspect{cursor_pos0.row, cursor_pos0.col},
  --   "other_side_pos0", vim.inspect{other_side_pos0.row, other_side_pos0.col},
  --   "start_pos0", vim.inspect{start_pos0.row, start_pos0.col},
  --   "end_pos0", vim.inspect{end_pos0.row, end_pos0.col},
  -- })
  return {
    start_pos0 = start_pos0,
    end_pos0 = end_pos0,
  }
end

return U_visual
