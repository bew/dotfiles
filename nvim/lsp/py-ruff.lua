-- https://docs.astral.sh/ruff/

---@type vim.lsp.Config
return {
  filetypes = { "python" },

  cmd = {"ruff", "server"},
  settings = {
    lineLength = 100,
    select = {"F", "E", "W", "N", "UP", "RUF"},
    extendSelect = {"RUF"}, -- Ensure these rules are always checked
  },
  single_file_support = true,

  root_markers = {
    "pyproject.toml",
    "requirements.txt",
    ".git",
    -- for legacy projects (e.g. in deps)
    "setup.py",
    "setup.cfg",
  },
}
