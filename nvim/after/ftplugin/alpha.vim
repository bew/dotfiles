" open current file with 'o'
nmap <buffer> o <cr>

" Edit new buffer with `i`
nmap <buffer> i <cmd>enew <bar> startinsert<cr>

" Show a full page of help!
" NOTE: I use <right> at the end to not have a trailing space in the config
nnoremap <buffer> <M-h> :h<cr><C-w>o:h <right>
let b:bew_statusline_comment = "Alt-h for help-only view"
