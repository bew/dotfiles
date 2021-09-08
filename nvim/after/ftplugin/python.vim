let g:neomake_python_enabled_makers = ["python", "flake8", "mypy"]

" I: Alt-, to insert a comma after cursor.
" * When the cursor is at EOL, inserts only ','
" * When the cursor is in text, inserts ', '
inoremap <buffer><expr> <M-,> (col(".") == col("$") ? ',<C-g>U<Left>' : ', <C-g>U<Left><C-g>U<Left>')

" I: Alt-f to toggle between `f"..."` and `"..."`
" NOTE that it is pretty dumb, and searches the first '"' on left of cursor.
function! s:PyFStringToggle()
  let saved_cursor = getcurpos()[1:]
  " Search the start of a python str
  " * option 'b': search backward from cursor
  " * option 'n': do NOT move the cursor
  let [lnum, col1] = searchpos('"', "bn", line("."))
  if lnum == 0 | return | endif " start of str not found

  " FIXME: this whole thing is MUCH simpler with nvim 0.5.0
  " by using `nvim_buf_set_text` which can insert text anywhere, while
  " preserving the cursor position (by extmarks standards).
  " TODO: rewrite once I completely moved to nvim 0.5.0.

  let line = getline(".")
  let line_before_str = (col1 == 1 ? "" : line[0:col1 -2])
  let line_from_str = (line[col1 - 1:])
  if line_before_str[-1:] == "f"
    " Before the start of the str, there's a `f`!
    let is_fstring = v:true
  else
    let is_fstring = v:false
  endif

  if is_fstring
    " remove the `f`
    let line_new = line_before_str[:-2] . line_from_str
    " Move cursor left
    let saved_cursor[1] = saved_cursor[1] - 1
  else
    " add the `f`
    let line_new = line_before_str . "f" . line_from_str
    " Move cursor right
    let saved_cursor[1] = saved_cursor[1] + 1
  endif
  call setline(lnum, line_new)
  call cursor(saved_cursor)
endf
inoremap <buffer> <M-f> <cmd>call <SID>PyFStringToggle()<cr>
