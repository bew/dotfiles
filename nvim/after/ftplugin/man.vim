setlocal nonumber
setlocal norelativenumber
setlocal nomodifiable
setlocal nolist

setlocal tabstop=8
setlocal wrapmargin=4
setlocal breakindent
setlocal incsearch


" Follow man page link
nnoremap <buffer><silent> <2-LeftMouse> :Man<cr>
nnoremap <buffer><silent> o :Man<cr>
" Open man page link in split (easy to move afterward)
nnoremap <buffer><silent> <M-o> :split <bar> Man<cr>

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
