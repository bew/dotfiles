" Center view on the quickfix entry while staying in the quickfix window
nnoremap <buffer> o  <cr>zz<C-w>p
nnoremap <buffer> O  <cr>zz<C-w>p
" Same but with movement
nnoremap <buffer> <M-j>  j<cr>zz<C-w>p
nnoremap <buffer> <M-k>  k<cr>zz<C-w>p

" Quick quit
" FIXME: how to disable quit when a macro is recording?
nnoremap <buffer> q :q<cr>
" Keep macro recording under Alt-q
nnoremap <buffer> <M-q> q

let b:bew_statusline_comment = "o: view | M-j/k: view n/p | M-q: macro | q: quit"
