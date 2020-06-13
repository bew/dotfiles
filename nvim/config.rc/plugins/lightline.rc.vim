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

" I resign to use the popular powerline "arrow" symbol, since the
" diagonal blocks usually does not render correctly with a lot of font..
" (the top/bottom are not 'exactly' at the top/bottom, -> looks pretty bad)
let g:lightline.separator = { 'left': '', 'right': '' }
let g:lightline.subseparator = { 'left': '', 'right': '' }
" let g:lightline.separator = { 'left': '', 'right': '' }
" let g:lightline.subseparator = { 'left': '', 'right': '' }

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
      \   'readonly': '%{&readonly && &ft != "help" ? "" : ""}',
      \   'modified': '%{&modified ? "+" : ""}',
      \   'lineinfoprogress': '%{LightLineProgress()} %l:%v',
      \ }
let g:lightline.component_function = {
      \   'filename': 'LightLineFilename',
      \   'filetype': 'LightLineFiletype',
      \   'progress': 'LightLineProgress',
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
  return fname == 'ControlP' ? g:lightline.ctrlp_item :
        \ fname == '__Tagbar__' ? g:lightline.fname :
        \ fname =~ '__Gundo\|NERD_tree' ? '' :
        \ &ft == 'vimfiler' ? vimfiler#get_status_string() :
        \ &ft == 'unite' ? unite#get_status_string() :
        \ &ft == 'vimshell' ? vimshell#get_status_string() :
        \ ('' != fname ? fname : '[No Name]')
endfunction

function! LightLineFiletype()
  return strlen(&filetype) ? &filetype : 'no ft'
endfunction

" one char wide solid vertical bar
let g:line_no_indicator_chars = [
      \  ' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'
      \  ]
function! LightLineProgress()
  " Old 'percent' version
  " return winwidth(0) > 50 ? line('.') * 100 / line('$') . '%' : ''

  " From plugin drzel/vim-line-no-indicator
  return LineNoIndicator()
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
