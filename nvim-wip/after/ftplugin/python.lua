
local function start_lsp_server()
  local pylsp_settings = { pylsp = { plugins = {} } }
  -- When pylsp-mypy is installed
  pylsp_settings.pylsp.plugins.pylsp_mypy = {
    live_mode = false, -- update mypy diags on save (not live)
    dmypy = true,
    report_progress = true,
    overrides = {
      true, -- special value to add plugin's default params for mypy
      "--check-untyped-defs", -- ensure all functions are checked!
    },
  }
  -- WHen python-lsp-ruff is installed
  pylsp_settings.pylsp.plugins.ruff = {
    enabled = true,
    extendSelect = {"RUF"}, -- Ensure these rules are always checked
    unsafeFixes = true, -- Offer unsafe fixes as code actions (Ignored for `Fix All`)

    -- Following settings are ignored if a pyproject.toml exists
    lineLength = 100,
    -- ref: https://docs.astral.sh/ruff/rules/
    select = {"F", "E", "W", "N", "UP", "RUF"},
  }

  vim.lsp.start {
    -- https://github.com/python-lsp/python-lsp-server
    name = "pylsp",
    cmd = {"pylsp"},
    capabilities = require"mylib.lsp".get_default_capabilities(),
    settings = pylsp_settings,
    single_file_support = true,

    root_dir = vim.fs.root(0, {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
    }),
  }
end
if vim.fn.executable("pylsp") == 1 then
  vim.notify("Starting LSP server..")
  start_lsp_server()
else
  vim.notify("LSP not found")
end

-------------------------------------------------------------------------------

-- I: <Alt-:> to insert a colon after cursor.
toplevel_buf_map{mode="i", key=[[<M-:>]], action=[[: <C-g>U<Left><C-g>U<Left>]]}

-- I: <Alt-f> to toggle between `f"..."` and `"..."`
-- NOTE: it is pretty dumb, searching the first '"' on left of cursor.
-- TODO: check with tree-sitter if in string + add support for multiline string
local function fstring_toggle()
  local saved_cursor = vim.api.nvim_win_get_cursor(0) -- (1, 0)-indexed
  local cur_row0, cur_col0 = saved_cursor[1] -1, saved_cursor[2]
  local line_before = vim.api.nvim_get_current_line():sub(1, cur_col0 +1)
  local quote_rel_idx1 = line_before:reverse():find('"')
  if not quote_rel_idx1 then
    vim.notify([[Cannot toggle f-string, not in string? 👀]])
    return
  end
  local quote_idx1 = #line_before - quote_rel_idx1 + 1
  local f_idx1 = quote_idx1 -1
  local is_fstring = line_before:sub(f_idx1, f_idx1) == "f"

  if is_fstring then
    -- Delete `f`
    local row0 = cur_row0
    local col0 = f_idx1 -1
    vim.api.nvim_buf_set_text(0, row0, col0, row0, col0 +1, {}) -- 0-indexed
    --vim.api.nvim_win_set_cursor(0, cur_row0 +1, ) -- (1, 0)-indexed
    --FIXME: finish this!
  else
    -- Insert `f` at quote position
    local row0 = cur_row0
    local col0 = quote_idx1 -1
    vim.api.nvim_buf_set_text(0, row0, col0, row0, col0, {"f"})
    --FIXME: finish this! (move cursor)
  end
end
toplevel_buf_map{mode="i", key=[[<M-f>]], action=fstring_toggle}
