-- Prevent the builtin ftplugin from running and defining its own commands
-- (want to use rustaceanvim!)
vim.b.did_ftplugin = 1

-- Allow both `///` & `//` (order matters) to be considered as a comment leader
-- (e.g. on gq or 'Enter' from a doc line when formatoptions includes 'r')
vim.o.comments = ":///,://"
