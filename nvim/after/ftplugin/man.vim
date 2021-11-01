setlocal nonumber
setlocal norelativenumber
setlocal nocursorcolumn
setlocal nomodifiable
setlocal nolist

setlocal tabstop=8
setlocal wrapmargin=4
setlocal breakindent
setlocal incsearch


" Follow man page link
nnoremap <buffer><silent> o <cmd>Man<cr>
nnoremap <buffer><silent> <2-LeftMouse> <cmd>Man<cr>
" Open man page link in split (easy to move afterward)
nnoremap <buffer><silent> <M-o> <cmd>split <bar> Man<cr>

" Scroll one line
noremap <buffer> j <C-e>
noremap <buffer> k <C-y>

" Backup for cursor up/down (can help with manual selections)
noremap <buffer> <M-j> j
noremap <buffer> <M-k> k

" Scroll half-screen
noremap <buffer> J <C-d>
noremap <buffer> K <C-u>

" Scroll screen
noremap <buffer> <Space> <C-d><C-d>
noremap <buffer> <S-Space> <C-u><C-u>

" Quit
" Always quit a man buffer with q (and its loc list if opened).
" This is necessary to work in all cases
" (when involked as manpager and when using :Man in existing vim session)
" See: https://github.com/neovim/neovim/issues/15544
nnoremap <buffer><silent> q <cmd>lclose <bar> q<cr>
nnoremap <buffer><silent> <M-q> q

let b:bew_statusline_comment = "o/2-clicks: open | M-o: split-open"
