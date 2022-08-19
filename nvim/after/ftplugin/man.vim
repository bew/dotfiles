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

" Scroll one line
noremap <buffer> j <C-e>
noremap <buffer> k <C-y>

" Backup for cursor up/down (can help with manual selections)
noremap <buffer> <M-j> j
noremap <buffer> <M-k> k

" Scroll half-screen
noremap <buffer> J <C-d>
noremap <buffer> K <C-u>

" Quit
" Always quit a man buffer with q (and its loc list if opened).
" This is necessary to work in all cases
" (when involked as manpager and when using :Man in existing vim session)
" See: https://github.com/neovim/neovim/issues/15544
nnoremap <buffer><silent> q <cmd>lclose <bar> q<cr>
nnoremap <buffer><silent> <M-q> q

nnoremap <buffer>  <M-o>  :Man <Right>

" Move cursor on next/previous help link
function! s:SearchManLink(backward)
  let flags = "wz" " w: wrap at eof | z: from cursor column not 0
  if a:backward
    let flags .= "b" " b: search backward
  endif
  " The help links format is: |some_stuff|
  " So we search for a | then some chars that are not spaces then |
  let pos = searchpos('\C[a-z][a-z0-9-]\+(\d)', flags)
  call cursor(pos)
endf
nnoremap <buffer><silent> <C-n>  :call <SID>SearchManLink(v:false)<cr>
nnoremap <buffer><silent> <C-p>  :call <SID>SearchManLink(v:true)<cr>


let b:bew_statusline_comment = "2-clicks/o: open at cursor | M-o: open new | C-n/p: find link"
