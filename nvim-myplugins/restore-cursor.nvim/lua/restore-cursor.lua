-- Inspired from (and rewritten/simplified by me, @bew):
-- https://github.com/neovim/neovim/issues/16339#issuecomment-1348133829
-- https://github.com/farmergreg/vim-lastplace/issues/28#issuecomment-1336129506

local buf_get_option = vim.api.nvim_buf_get_option -- (shorter)

local M = {}

local function restore_cursor(cfg, ctx)
  local last_known_pos = vim.api.nvim_buf_get_mark(ctx.buf, '"')
  ctx.last_known = { line1 = last_known_pos[1], col0 = last_known_pos[2] }
  ctx.restored = false
  ctx.out_of_bound = false

  -- If a line has already been specified on the command line, we are done
  --   nvim file +num
  if vim.fn.line(".") > 1 then
    cfg.after_fn(ctx)
    return
  end

  if ctx.last_known.line1 == 0 then
    -- Last known line is not set, do nothing
    return
  elseif ctx.last_known.line1 > vim.api.nvim_buf_line_count(ctx.buf) then
    -- Last known line is out of bound
    -- (can happen if the file was changed outside of nvim and is now shorter)
    ctx.out_of_bound = true
  else
    -- Last known line exists, let's move cursor to last known position!
    -- vim.api.nvim_feedkeys([[g`"]], "x", false) -- ("x": for 'execute this now please')
    vim.api.nvim_win_set_cursor(ctx.winid, {ctx.last_known.line1, ctx.last_known.col0})
    -- print(
    --   "restored cursor for winid:", ctx.winid,
    --   "to position (L1, C0):", vim.inspect(last_known_pos)
    -- )
    ctx.restored = true
  end

  cfg.after_fn(ctx)
end

M.default_config = {
  enable_when = function(ctx)
    local buftype = buf_get_option(ctx.buf, "buftype")
    if vim.tbl_contains({ "quickfix", "nofile", "help" }, buftype) then
      return false
    end
    local filetypes = vim.split(buf_get_option(ctx.buf, "filetype"), ".", {plain=true})
    for _, ft in ipairs(filetypes) do
      if vim.tbl_contains({ "gitcommit", "gitrebase" }, ft) then
        return false
      end
    end
    return true
  end,

  after_fn = function(ctx)
    if not ctx.restored then
      -- FIXME: Doing that `zz` when `not ctx.restored` doesn't seem to do anything :/
      return
    end
    if ctx.out_of_bound then
      -- Move cursor to last line (and try restore column)
      local buf_line_count = vim.api.nvim_buf_line_count(ctx.buf)
      vim.api.nvim_win_set_cursor(ctx.winid, {buf_line_count, ctx.last_known.col0})
      return
    end
    -- IDEA: Instead of simply centering on cursor, it could be smarter by looking at the
    --   surrounding function (via TS) and try to show the whole function containing cursor.
    --   (if it fits on screen)
    vim.cmd[[normal! zz]]
  end,
}

function M.setup(given_cfg)
  local cfg = vim.tbl_extend("force", M.default_config, given_cfg or {})

  -- BufRead(all): We're starting to edit a new buffer
  -- BufWinEnter(once for new buf): We're viewing this buffer for the 1st time in a window
  -- => restore cursor
  vim.api.nvim_create_autocmd("BufRead", {
    callback = function(event)
      -- FIXME: 'BufWinEnter' triggers ONCE when opening the same buffer in multiple splits or tabs
      -- (e.g: using `nvim foo.txt foo.txt -o` (or `-p`))
      -- I think I really want to do something the first time a buffer is displayed in every window
      --
      -- Added comment about this here:
      -- https://github.com/neovim/neovim/issues/16339#issuecomment-1462917655
      -- With an idea of autocmd to trigger everytime a buffer is displayed in a window:
      -- https://github.com/neovim/neovim/issues/22597
      vim.api.nvim_create_autocmd("BufWinEnter", {
        -- once = true, -- Ensure it's called ONCE (not everytime the buffer is displayed)
        buffer = event.buf,
        callback = function()
          local ctx = {
            buf = event.buf,
            winid = vim.fn.win_getid(vim.fn.winnr(), vim.fn.tabpagenr()),
          }
          if not cfg.enable_when(ctx) then return end
          restore_cursor(cfg, ctx)
        end,
      })
    end,
  })
end

return M
