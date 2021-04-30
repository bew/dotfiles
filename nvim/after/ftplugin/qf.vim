" Center view on the quickfix entry while staying in the quickfix window
nnoremap <buffer> o  <cr>zz<C-w>p
nnoremap <buffer> O  <cr>zz<C-w>p
" Same but with movement
nnoremap <buffer> <M-j>  j<cr>zz<C-w>p
nnoremap <buffer> <M-k>  k<cr>zz<C-w>p

let b:bew_statusline_comment = "o: preview | M-j/k: preview next/previous"
