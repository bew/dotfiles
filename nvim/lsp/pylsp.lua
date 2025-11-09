
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

---@type vim.lsp.Config
return {
  filetypes = { "python" },

  -- https://github.com/python-lsp/python-lsp-server
  cmd = {"pylsp"},
  settings = pylsp_settings,
  single_file_support = true,

  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },
}
