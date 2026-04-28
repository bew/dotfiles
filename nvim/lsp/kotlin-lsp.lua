---@type vim.lsp.Config
return {
  filetypes = { 'kotlin' },
  cmd = { 'kotlin-lsp', '--stdio' },
  root_markers = {
    "settings.gradle.kts", -- Gradle (multi-project)
    "build.gradle.kts", -- Gradle
  },
}
