-- https://github.com/bash-lsp/bash-language-server

---@type vim.lsp.Config
return {
  filetypes = {
    "bash",
    "sh",
    "zsh", -- limited wupport, may give false positive/negatives for weird zsh syntax
  },

  cmd = { "bash-language-server", "start" },
  single_file_support = true,
  root_markers = { ".git" },

  settings = {
    -- See config options in:
    -- https://github.com/bash-lsp/bash-language-server/blob/main/vscode-client/package.json
    -- (under `contributes > configuration > properties > bashIde.*`, near EOF)
    bashIde = {
      -- Prevent recursive scanning, which cause issues for top-level files (e.g. ~/foo.sh).
      -- (default is "**/*@(.sh|.inc|.bash|.command)" #yolo)
      globPattern = "*@(.sh|.zsh)",
    },
  },
}
