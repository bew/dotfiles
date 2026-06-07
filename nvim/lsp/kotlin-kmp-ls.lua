-- https://github.com/Hessesian/kmp-lsp
-- Fast, low-memory LSP server for Kotlin and Java, written in Rust

---@type vim.lsp.Config
return {
  filetypes = { "kotlin", "java", "swift" },

  cmd = { "kmp-lsp" },
  root_markers  = {
    "settings.gradle.kts", -- Gradle (multi-project)
    "build.gradle.kts", -- Gradle
    "pom.xml",
    "Package.swift",
    ".git"
  },

  settings  = {},
}
