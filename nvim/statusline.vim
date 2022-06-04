" Statusline Configuration
" --------------------------------------------------------------------

" Using 'lightline' plugin as the statusline
let g:lightline = {}
let g:lightline.enable = {
    \   'statusline': v:true,
    \   'tabline': v:false,
    \ }

let g:lightline.mode_map = {
    \   'n': 'N', 'i': 'I', 'R': 'R',
    \   'v': 'V', 'V': 'VL', "\<C-v>": 'VB',
    \   's': 'S', 'S': 'SL', "\<C-s>": 'SB',
    \   'c': 'C', 't': 'T',
    \   '?': '?!',
    \ }

" Use simple separators
let g:lightline.separator = { 'left': '', 'right': '' }
let g:lightline.subseparator = { 'left': '│', 'right': '│' }

" Custom colorscheme is stored in: 'autoload/lightline/colorscheme/NAME.vim'
let g:lightline.colorscheme = 'bew'

let g:lightline.active = {
    \   'left': [
    \     ['mode', 'paste'],
    \     ['readonly', 'filename', 'linter_err_warn', 'modified'],
    \     ['git_branch', 'buffer_comment']
    \   ],
    \   'right': [
    \     ['lineinfoprogress'],
    \     [],
    \     ['filetype']
    \   ],
    \ }
let g:lightline.inactive = {
    \   'left':  [
    \     ['mode'],
    \     ['readonly', 'relativepath', 'linter_err_warn', 'modified'],
    \     ['git_branch', 'realpath']
    \   ],
    \   'right': [
    \     ['progress'],
    \     [],
    \     ['filetype']
    \   ],
    \ }

let g:lightline.component = {
    \   'readonly': '%{&readonly && &ft != "help" && &ft != "startify" ? "RO" : ""}',
    \   'modified': '%{&modified ? "+" : ""}',
    \   'lineinfoprogress': '%P %l:%02v',
    \   'progress': '%P L%l',
    \ }
" This controls the visibility of the component subseparator
" (before for a left component, after for a right component).
let g:lightline.component_visible_condition = {
    \   'readonly': '&readonly && &ft != "help" && &ft != "startify"',
    \   'modified': '&modified',
    \ }
let g:lightline.component_function = {
    \   'filename': 'StatuslineTwoPartsFilename',
    \   'relativepath': 'StatuslineTryRelativeFilename',
    \   'realpath': 'StatuslineRealpathIfDiff',
    \   'filetype': 'StatuslineFiletype',
    \   'mode': 'StatuslineMode',
    \   'git_branch': 'StatuslineGitBranch',
    \   'buffer_comment': 'StatuslineBufferComment',
    \   'linter_err_warn': 'StatuslineLinterErrorsAndWarnings',
    \ }

function! StatuslineGitBranch()
  if expand('%:t') =~? 'Mundo\|NERD'
    return ''
  endif

  if &ft == 'man'
    " The branch isn't useful here!
    return ''
  endif

  try
    let mark = 'On '
    let branch = fugitive#Head()
    return branch !=# '' ? mark . branch : ''
  catch
  endtry
  return ''
endfunction

function! s:special_buffer_name()
  let wininfo = getwininfo(win_getid())[0]
  " let r = getwininfo(win_getid())[0] | echo "qf: " . r.quickfix . " loc: " . r.loclist
  let is_qf_list = (wininfo.quickfix && !wininfo.loclist)  " qf: 1 && loc: 0
  let is_loc_list = (wininfo.quickfix && wininfo.loclist)  " qf: 1 && loc: 1
  let filename = expand('%:t')

  if is_qf_list
    return "[Quickfix List]"
  elseif is_loc_list
    return "[Location List]"
  endif

  if &filetype == "help"
    return filename
  elseif &filetype == "startify"
    return "Startify"
  endif

  if filename == "__Mundo__"
    return "Undo Tree"
  elseif filename == "__Mundo_Preview__"
    return "Preview"
  elseif filename =~ "NERD_tree"
    return "NTree"
  elseif filename == "__committia_diff__"
    return "Diff"
  endif

  return "__not_special__"
endf

function! StatuslineRealpathIfDiff()
  let buffer_name = expand('%')
  let fullpath = fnamemodify(buffer_name, ':p')
  let resolved_fullpath = resolve(fullpath)
  if filereadable(buffer_name) && fullpath != resolved_fullpath
    let formatted_realpath = fnamemodify(resolved_fullpath, ':~')
    return 'Realpath: ' . formatted_realpath
  else
    return ''
  endif
endf

function! s:path_try_to_relative(valid_path)
  " Transform to relative path to (tab/process's) cwd or absolute path
  let path = fnamemodify(a:valid_path, ':p:.')
  if path =~? '^/'
    " path is absolute, at least try to apply '~' home substitution
    return fnamemodify(path, ':~')
  else
    " path is not absolute, it's relative, add './' to be explicit
    return './' . path
  endif
endf

function! s:path_to_2_parts(valid_path)
  " Transform to 2-parts file path: ~/foo or foo/bar
  let raw_fname = fnamemodify(a:valid_path, ':t')
  if filereadable(expand("~/" . raw_fname))
    return "~/" . raw_fname " ~/filename
  else
    let parent_dir = expand("%:h:t")
    return parent_dir . "/" . raw_fname " parent_dir/filename
  endif
endf

function! s:buffer_name_with_transformation(path_transformer)
  let buffer_name = expand('%')
  if filereadable(buffer_name)
    " It's a file path, transform it!
    let formatted_path = a:path_transformer(buffer_name)
  else
    " It's not a file path, just put its name (e.g: '__XtermColorTable__')
    let formatted_path = (buffer_name != "" ? buffer_name : "[No Name]")
  endif

  let special_name = s:special_buffer_name()
  return special_name != "__not_special__" ? special_name : formatted_path
endf

function! StatuslineTryRelativeFilename()
  return s:buffer_name_with_transformation(funcref('s:path_try_to_relative'))
endf

function! StatuslineTwoPartsFilename()
  return s:buffer_name_with_transformation(funcref('s:path_to_2_parts'))
endfunction

function! StatuslineFiletype()
  if LanguageClient#isServerRunning()
    return &filetype . "[LC]"
  endif
  return strlen(&filetype) ? &filetype : 'no ft'
endfunction

function! StatuslineMode()
  if &ft == 'help'
    if mode() == 'n' || mode() == 'c'
      return 'help'
    else
      return lightline#mode() . ' help'
    endif
  endif

  return lightline#mode()
endfunction

function! StatuslineBufferComment()
  return get(b:, "bew_statusline_comment", "")
endf

function! StatuslineLinterErrorsAndWarnings()
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

  let err_str = (l:err_count != 0 ? "E".l:err_count : "")
  let warn_str = (l:warn_count != 0 ? "W".l:warn_count : "")
  if l:err_str != "" && l:warn_str != ""
    " Both are set, separate them
    return l:err_str ." ". l:warn_str
  else
    " Only one is set, concat
    " (only the non-empty one will be visible anyway)
    return l:err_str . l:warn_str
  endif
endf
