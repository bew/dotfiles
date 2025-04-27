local K = require"mylib.keymap_system"

local function start_lsp_server()
  local venv_py_exec
  if vim.env.VIRTUAL_ENV and vim.uv.fs_stat(vim.env.VIRTUAL_ENV .. "/bin/python") then
    venv_py_exec = vim.env.VIRTUAL_ENV .. "/bin/python"
  end

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
  if venv_py_exec then
    -- Ensure mypy can find imports in the currently activated venv
    -- ref: https://github.com/python/mypy/issues/17214
    vim.list_extend(pylsp_settings.pylsp.plugins.pylsp_mypy.overrides, {
      "--python-executable",
      venv_py_exec,
    })
  end

  -- When python-lsp-ruff is installed
  pylsp_settings.pylsp.plugins.ruff = {
    enabled = true,
    extendSelect = {"RUF"}, -- Ensure these rules are always checked
    unsafeFixes = true, -- Offer unsafe fixes as code actions (Ignored for `Fix All`)

    -- Following settings are ignored if a pyproject.toml exists
    lineLength = 100,
    -- ref: https://docs.astral.sh/ruff/rules/
    select = {"F", "E", "W", "N", "UP", "RUF"},

    -- Edit severity for some rules.
    -- By default "E999" and "F" rules are marked as errors, all other rules are marked as warnings.
    severities = {
      -- Warning
      F401 = "W", -- {name} imported but unused
      F541 = "W", -- f-string without any placeholders
      -- Hints
      F841 = "H", -- Local variable {name} is assigned to but never used
      F842 = "H", -- Local variable {name} is annotated but never used
    },
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
K.toplevel_buf_map{mode="i", key=[[<M-:>]], action=[[: <C-g>U<Left><C-g>U<Left>]]}

-- I: <Alt-f> to toggle between `f"..."` and `"..."`
local function fstring_toggle()
  vim.treesitter.get_parser():parse() -- ensure tree is parsed
  local node = vim.treesitter.get_node()
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
