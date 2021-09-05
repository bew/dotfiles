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
let g:lightline.subseparator = { 'left': '|', 'right': '|' }

let g:lightline.colorscheme = 'PaperColor'

let g:lightline.active = {
      \   'left': [
      \     ['mode', 'paste'],
      \     ['linter_err_warn', 'filename', 'readonly', 'modified'],
      \     ['fugitive', 'language_client_active', 'buffer_comment']
      \   ],
      \   'right': [
      \     ['lineinfoprogress'],
      \     [],
      \     ['filetype']
      \   ],
      \ }
let g:lightline.inactive = {
      \   'left':  [
      \     ['relativepath', 'readonly', 'modified'],
      \     ['fugitive', 'buffer_comment']
      \   ],
      \   'right': [
      \     ['progress'],
      \     ['filetype']
      \   ],
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
      \   'linter_err_warn': 'LightLineLinterErrorsAndWarnings',
      \   'language_client_active': 'LightLineLanguageClientActive',
      \ }

function! LightlineFugitive()
  if expand('%:t') =~? 'Mundo\|NERD'
    return ''
  endif

  if &ft == 'man'
    " The branch isn't useful here!
    return ''
  endif

  try
    let mark = 'On '
    let branch = fugitive#head()
    return branch !=# '' ? mark . branch : ''
  catch
  endtry
  return ''
endfunction

function! LightLineLanguageClientActive()
  if LanguageClient#isServerRunning()
    return "LC active"
  endif
  return ""
endf

function! LightLineFilename()
  let wininfo = getwininfo(win_getid())[0]
  " let r = getwininfo(win_getid())[0] | echo "qf: " . r.quickfix . " loc: " . r.loclist
  let is_qf_list = (wininfo.quickfix && !wininfo.loclist)  " qf: 1 && loc: 0
  let is_loc_list = (wininfo.quickfix && wininfo.loclist)  " qf: 1 && loc: 1

  let raw_fname = expand('%:t')
  if raw_fname != ""
    if filereadable(expand("~/" . expand('%:t')))
      let formatted_fname = "~/" . expand("%:t") " ~ & filename
    else
      let formatted_fname = expand("%:h:t") . "/" . expand("%:t") " parent dir & filename
    endif
  elseif is_qf_list
    let formatted_fname = "[Quickfix List]"
  elseif is_loc_list
    let formatted_fname = "[Location List]"
  else
    let formatted_fname = "[No Name]"
  endif

  let plugin_fname = "not-a-plugin"
  if raw_fname == "__Mundo__"
    let plugin_fname = "Mundo"
  elseif raw_fname == "__Mundo_Preview__"
    let plugin_fname = "Preview"
  elseif raw_fname =~ "NERD_tree"
    let plugin_fname = ""
  elseif raw_fname == "__committia_diff__"
    let plugin_fname = "commit diff"
  elseif &filetype == "startify"
    let plugin_fname = ""
  endif

  return plugin_fname != "not-a-plugin" ? plugin_fname : formatted_fname
endfunction

function! LightLineFiletype()
  return strlen(&filetype) ? &filetype : 'no ft'
endfunction

function! LightLineMode()
  if &ft == 'help'
    return 'H'
  endif

  let fname = expand('%:t')
  let plugin_mode = "not-a-plugin"
  if fname == "__Mundo__" || fname == "__Mundo_Preview__"
    let plugin_mode = ""
  elseif fname =~ "NERD_tree"
    let plugin_mode = ""
  elseif &filetype == "startify"
    let plugin_mode = "Startify"
  endif

  return plugin_mode != "not-a-plugin" ? plugin_mode : lightline#mode()
endfunction

function! LightLineBufferComment()
  return get(b:, "bew_statusline_comment", "")
endf

function! LightLineLinterErrorsAndWarnings()
  let l:err_count = 0
  let l:warn_count = 0

  if LanguageClient#isServerRunning()
    try
      let l:lc_status = LanguageClient#statusLineDiagnosticsCounts()
      let l:err_count = get(l:lc_status, "E", 0)
      let l:warn_count = get(l:lc_status, "W", 0)
    catch
    endtry
  else
    try
      let l:nm_status = neomake#statusline#LoclistCounts()
      let l:err_count = get(l:nm_status, "E", 0)
      let l:warn_count = get(l:nm_status, "W", 0)
    catch
    endtry
  endif

  let err_str = (l:err_count != 0 ? "E:".l:err_count : "")
  let warn_str = (l:warn_count != 0 ? "W:".l:warn_count : "")
  if l:err_str != "" && l:warn_str != ""
    " Both are set, separate them
    return l:err_str ." ". l:warn_str
  else
    " Only one is set, concat
    " (only the non-empty one will be visible anyway)
    return l:err_str . l:warn_str
  endif
endf
