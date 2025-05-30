-- FIXME: &rtp and &pp defaults to loaaads of stuff on NixOS, using the
-- maannyyyy dirs from XDG_CONFIG_DIRS & XDG_DATA_DIRS...
-- => Remove the ones from these folders that don't actually exist?

-- TODO: re-enable, and contribute fixes to all plugins with undefined global vars..
--_G = setmetatable(_G, {
--  __index = function(_, key)
--    error("Unknown global variable '" .. key .. "'")
--  end,
--})

-- Load options early in case the initialization of some plugin requires them.
-- (e.g: for filetype on)
require"mycfg.options"

-- NOTE: If trying to move it AFTER plugin load, double check git signs are of correct color!
vim.cmd[[ colorscheme bew256-dark ]]
vim.opt.termguicolors = false -- TODO: convert my theme to RGB!

-- Map leaders
local TERM_CODES = require"mylib.term_codes"
vim.g.mapleader = TERM_CODES.C_Space
vim.g.maplocalleader = TERM_CODES.Space
-- NOTE: Special termcode (like `<foo>`) must be replaced to avoid _very_ unexpected behavior
--   See: https://github.com/neovim/neovim/issues/27826 😬

require"mycfg.mappings"

-- ------ PLUGINS
require"mycfg.plugs".boot_plugins {
  install_dir = vim.fn.stdpath"state" .. "/managed-plugins/start",
}

require"mycfg.diagnostics_setup"
require"mycfg.lsp_setup"

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.highlight.on_yank{ timeout = 300 }
  end,
})
