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
  let raw_fname = expand('%:t')
  if raw_fname != ""
    if filereadable(expand("~/" . expand('%:t')))
      let formatted_fname = "~/" . expand("%:t") " ~ & filename
    else
      let formatted_fname = expand("%:h:t") . "/" . expand("%:t") " parent dir & filename
    endif
  else
    let formatted_fname = "[No Name]"
  endif

  let plugin_fname = ""
  if raw_fname == "__Mundo__"
    let plugin_fname = "Mundo"
  elseif raw_fname == "__Mundo_Preview__"
    let plugin_fname = "Mundo Prev"
  elseif raw_fname =~ "NERD_tree"
    let plugin_fname = ""
  endif

  return plugin_fname != "" ? plugin_fname : formatted_fname
endfunction

function! LightLineFiletype()
  return strlen(&filetype) ? &filetype : 'no ft'
endfunction

function! LightLineMode()
  if &ft == 'help'
    return 'H'
  endif

  let fname = expand('%:t')
  let plugin_mode = ""
  if fname == "__Mundo__"
    let plugin_mode = "Mundo"
  elseif fname == "__Mundo_Preview__"
    let plugin_mode = "Mundo Prev"
  elseif fname =~ "NERD_tree"
    let plugin_mode = "Tree"
  endif

  return plugin_mode != "" ? plugin_mode : lightline#mode()
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
