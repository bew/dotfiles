" Fast quit
nnoremap <buffer> q  :q<cr>

" Go to help hyper link
nnoremap <buffer> o  <C-]>

" More logical next/previous jump
nnoremap <buffer> <M-p>  <C-o>
nnoremap <buffer> <M-n>  <C-i>

" Move cursor on next/previous help link
function! s:SearchHelpLink(backward)
  let flags = "wz" " w: wrap at eof | z: from cursor column not 0
  if a:backward
    let flags .= "b" " b: search backward
  endif
  " The help links format is: |some_stuff|
  " So we search for a | then some chars that are not spaces then |
  let pos = searchpos("|[^ ]\\{-}|", flags)
  call cursor(pos)
endf
nnoremap <buffer><silent> <C-n>  :call <SID>SearchHelpLink(v:false)<cr>
nnoremap <buffer><silent> <C-p>  :call <SID>SearchHelpLink(v:true)<cr>

" Set statusline comment for this buffer
let b:bew_statusline_comment = "o: follow link | C-n/C-p: find n/p link | M-n/M-p: n/p jump | q: quit"
