if &buftype != "help"
  " We're probably editing a help file, we don't want these helpers when
  " writing one!
  finish
endif

" Fast quit
nnoremap <buffer> q  :q<cr>

" Fast more-help
" NOTE: I use <right> to not have a trailing space in the config
nnoremap <buffer> <M-h> :h <right>

" Go to help hyper link
nnoremap <buffer> o  <C-]>

" More logical next/previous jump
nnoremap <buffer> <M-p>  <C-o>
nnoremap <buffer> <M-n>  <C-i>

" Move cursor on next/previous help link
"
" FIXME: does not handle options links (format: 'someoption')
"   /'[a-z]\{-\}'
" But it also matches in code example... Would need to detect those using the
" syntax group maybe? Or do the search for the code delimiters (can be tricky,
" since they aren't always present)
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
let b:bew_statusline_comment = "o: open | C-n/p: find link | M-n/p: n/p jump | M-h: :h"
