setlocal nonumber
setlocal norelativenumber
setlocal nomodifiable
setlocal nolist

setlocal tabstop=8
setlocal wrapmargin=4
setlocal breakindent
setlocal incsearch



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
