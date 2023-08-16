" What to open when doing `K` on a word
" Using `:help` allows us to get vim-related help of lua function
setlocal keywordprg=:help
" (It's a minimal solution..)
"
" TODO: A better solution would be to call a function, and impl a custom logic to search in
" `luaref-*` help tags first, if it starts with `nvim_` search in `vim.api.*` help tags, ..
" OR BETTER YET: use one of the lua-specific dev plugins implemented by the community, to enhance
" NVim-specific Lua writing :)
