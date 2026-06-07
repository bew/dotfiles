-- https://github.com/Kotlin/kotlin-lsp

---@type vim.lsp.Config
return {
  filetypes = { "kotlin" },

  cmd = { "kotlin-lsp", "--stdio" },
  root_markers = {
    ".git",
    "settings.gradle.kts", -- Gradle (multi-project)
    "build.gradle.kts", -- Gradle
  },
}
