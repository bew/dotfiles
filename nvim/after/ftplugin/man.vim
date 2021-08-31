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

" Scroll half-screen
noremap <buffer> J <C-d>
noremap <buffer> K <C-u>

" Scroll screen
noremap <buffer> <Space> <C-d><C-d>
noremap <buffer> <S-Space> <C-u><C-u>

" Quit
noremap <buffer> q :q<CR>

let b:bew_statusline_comment = "o/2-clicks: open | M-o: split-open"
