-- https://docs.astral.sh/ruff/

---@type vim.lsp.Config
return {
  filetypes = { "python" },

  cmd = {"ruff", "server"},
  init_options = {
    -- https://docs.astral.sh/ruff/editors/settings/
    settings = {
      lineLength = 100,
      -- Let configs in `pyproject.toml`/… to override editor settings
      configurationPreference = "filesystemFirst",
      lint = {
        select = {"F", "E", "W", "N", "UP", "RUF"},
        extendSelect = {"RUF"}, -- Ensure these rules are always checked
        ignore = {
          "F841", -- unused variables (already reported by the LSP)
        },
      },
    },
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
