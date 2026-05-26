-- https://pyrefly.org/

---@type vim.lsp.Config
return {
  filetypes = { "python" },

  cmd = {"pyrefly", "lsp"},
  init_options = {
    -- https://pyrefly.org/en/docs/IDE/#lsp-initializationoptions
    pyrefly = {
      analysis = {
        showHoverGoToLinks = false, -- bad rendering in Neovim.. :/
      },
      -- Disabled features...
      disabledLanguageServices = {
        semanticTokens = true, -- I prefer TS-based highlighting 👀
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
