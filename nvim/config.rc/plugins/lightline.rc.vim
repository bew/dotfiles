" LightLine Configuration :

let g:lightline = {}
let g:lightline.enable = {
      \     'statusline': 1,
      \     'tabline': 0,
      \   }

let g:lightline.mode_map = {
      \     'n': 'N', 'i': 'I', 'R': 'R',
      \     'v': 'V', 'V': 'VL', "\<C-v>": 'VB',
      \     's': 'S', 'S': 'SL', "\<C-s>": 'SB',
      \     'c': 'C', 't': 'T',
      \     '?': '?!',
      \   }

" Use simple separators (I resigned...)
let g:lightline.separator = { 'left': '', 'right': '' }
let g:lightline.subseparator = { 'left': '', 'right': '' }

let g:lightline.colorscheme = 'PaperColor'

let g:lightline.active = {
      \   'left': [ ['mode', 'paste'], ['linter_warnings', 'linter_errors', 'filename', 'readonly', 'modified'], ['fugitive', 'buffer_comment'] ],
      \   'right': [ ['lineinfoprogress'], [], ['filetype'] ],
      \ }
let g:lightline.inactive = {
      \   'left':  [ ['relativepath', 'readonly', 'modified'], ['fugitive', 'buffer_comment'] ],
      \   'right': [ ['progress'], ['filetype'] ],
      \ }
let g:lightline.component = {
      \   'readonly': '%{&readonly && &ft != "help" ? "RO" : ""}',
      \   'modified': '%{&modified ? "+" : ""}',
      \   'lineinfoprogress': '%P %l:%02v',
      \   'progress': '%P L%l',
      \ }
let g:lightline.component_function = {
      \   'filename': 'LightLineFilename',
      \   'filetype': 'LightLineFiletype',
      \   'mode': 'LightLineMode',
      \   'fugitive': 'LightlineFugitive',
      \   'buffer_comment': 'LightLineBufferComment',
      \   'linter_errors': 'LightLineLinterErrors',
      \   'linter_warnings': 'LightLineLinterWarnings',
      \ }
let g:lightline.component_type = {
    \   'linter_errors': 'error',
    \   'linter_warnings': 'warning',
    \ }

" Taken from: `:h lightline-powerful-example`
function! LightlineFugitive()
  try
    if expand('%:t') !~? 'Tagbar\|Gundo\|NERD' && exists('*fugitive#head')
      let mark = 'On '
      let branch = fugitive#head()
      return branch !=# '' ? mark . branch : ''
    endif
  catch
  endtry
  return ''
endfunction

function! LightLineFilename()
  let fname = expand('%:t')
  if filereadable(expand("~/" . expand('%:t')))
    let formatted_filename = "~/" . expand("%:t") " ~ & filename
  else
    let formatted_filename = expand("%:h:t") . "/" . expand("%:t") " parent dir & filename
  endif
  return fname == 'ControlP' ? g:lightline.ctrlp_item :
        \ fname == '__Tagbar__' ? g:lightline.fname :
        \ fname =~ '__Mundo\|NERD_tree' ? '' :
        \ &ft == 'vimfiler' ? vimfiler#get_status_string() :
        \ &ft == 'unite' ? unite#get_status_string() :
        \ &ft == 'vimshell' ? vimshell#get_status_string() :
        \ ('' != fname ? formatted_filename : '[No Name]')
endfunction

function! LightLineFiletype()
  return strlen(&filetype) ? &filetype : 'no ft'
endfunction

function! LightLineMode()
  if &ft == 'help'
    return 'H'
  endif

  let fname = expand('%:t')
  return fname == '__Tagbar__' ? 'Tagbar' :
        \ fname == '__Gundo__' ? 'Gundo' :
        \ fname == '__Gundo_Preview__' ? 'Gundo Preview' :
        \ fname =~ 'NERD_tree' ? 'NERDTree' :
        \ &ft == 'unite' ? 'Unite' :
        \ &ft == 'vimfiler' ? '' :
        \ &ft == 'vimshell' ? 'VimShell' :
        \ winwidth(0) > 60 ? lightline#mode() : ''
endfunction

function! LightLineBufferComment()
  return exists("b:bew_statusline_comment") ? b:bew_statusline_comment : ''
endf

function! LightLineLinterErrors()
  try
    let status = neomake#statusline#LoclistCounts()
    return status['E'] == 0 ? '' : 'E:' . status['E']
  catch
    return ''
  endtry
endf

function! LightLineLinterWarnings()
  try
    let status = neomake#statusline#LoclistCounts()
    return status['W'] == 0 ? '' : 'W:' . status['W']
  catch
    return ''
  endtry
endf
