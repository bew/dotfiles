" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file.
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \ exe "normal! g`\"" |
    \ endif

" Close the auto-completion preview window when leaving insert mode
" (disabled in the cmdline-window which does not have a preview window)
autocmd InsertLeave * if pumvisible() == 0 && getcmdwintype() == "" | pclose | endif

" vim -b : edit binary using xxd-format!
augroup binary_file_handling
  au!
  au BufReadPre  *.bin let &bin=1

  au BufReadPost *.bin if &bin | %!xxd
  au BufReadPost *.bin set ft=xxd | endif

  au BufWritePre *.bin if &bin | %!xxd -r
  au BufWritePre *.bin endif

  au BufWritePost *.bin if &bin | %!xxd
  au BufWritePost *.bin set nomod | endif
augroup END
