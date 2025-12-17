-- https://docs.astral.sh/ty/

---@type vim.lsp.Config
return {
  filetypes = { "python" },

  cmd = {"ty", "server"},
  settings = {
    ty = {
      -- This is only for editor settings (https://docs.astral.sh/ty/reference/editor-settings/)
      -- Other ty configs (https://docs.astral.sh/ty/reference/configuration/) is ONLY done
      -- through `pyproject.toml` or `ty.toml`.
      -- ISSUE: https://github.com/astral-sh/ty/issues/1084 & https://github.com/astral-sh/ty/issues/786
      --   (👉 they want to expose more config options at editor-level)
      -- rules = {
      --   ["undefined-reveal"] = "ignore",
      -- },
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
