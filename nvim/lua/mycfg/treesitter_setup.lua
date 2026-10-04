-- Treesitter setup
-- --------------------------------------------------------------------

-- Tree-sitter resolves a markdown fenced code block's info string through
-- vim.treesitter.language.get_lang(), so aliases must be registered to map
-- them onto an existing parser.
-- e.g. ```md should render/highlight the same as ```markdown.
vim.treesitter.language.register("markdown", "md")
