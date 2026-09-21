vim.api.nvim_create_user_command("LiveMessages", function(opts)
  -- Deferred require keeps this startup script cheap (see :help lua-plugin-defer-require).
  require"live-messages".actions.open(opts)
end, {
  desc = "Open the live :messages buffer (accepts :vert/:horiz/:aboveleft modifiers)",
})

vim.api.nvim_create_user_command("LiveMessagesMark", function(opts)
  require"live-messages".actions.mark(opts.args)
end, {
  nargs = "?",
  desc = "Insert a labelled marker into the live :messages buffer",
})