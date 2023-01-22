-- VIM - mappings
-- --------------------------------------------------------------------
-- 'I speak vim' - bew, 2021

-- TODO: Add tags! Define layers!

-- Disable keybindings

-- <C-LeftMouse> default to <C-]>, which just give errors in most files..
-- I'll re-enable it in a smart way whenever I really want it!
vim.cmd[[nnoremap <C-LeftMouse> <nop>]]

----- Survival keybindings..

-- N,I,V: Save buffer
vim.cmd[[nnoremap <silent> <M-s> :w<cr>]]
vim.cmd[[inoremap <silent> <M-s> <Esc>:w<cr>]]
vim.cmd[[vnoremap <silent> <M-s> <Esc>:w<cr>]]

-- N: Quit window
vim.cmd[[nnoremap <silent> Q :q<cr>]]


-- N: logical redo
vim.cmd[[nnoremap U <C-r>]]

-- N: Y to copy whole line
vim.cmd[[nnoremap Y yy]]

-- N: Discard last search highlight
vim.cmd[[nnoremap <silent> § :noh \| echo "Search cleared"<cr>]]

-- I: Disable up/down keys
--
-- This is required to disable scrolling in insert mode when running under tmux with scrolling
-- emulation mouse bindings for the alternate screen, because it would move Up/Down N times based on
-- the scrolling emulation config.
vim.cmd[[inoremap <Up> <nop>]]
vim.cmd[[inoremap <Down> <nop>]]

-- Windows navigation
vim.cmd[[nnoremap <C-h> <C-w>h]]
vim.cmd[[nnoremap <C-j> <C-w>j]]
vim.cmd[[nnoremap <C-k> <C-w>k]]
vim.cmd[[nnoremap <C-l> <C-w>l]]
-- When mapping <C-j> has no effect
--vim.cmd[[nmap <cr> <C-j>]]
--
-- When mapping <C-h> has no effect
--vim.cmd[[nmap <BS> <C-h>]]

-- I: CTRL-U with undo point to avoid loosing text by mistake
--vim.cmd[[inoremap <C-u> <C-g>u<C-u>]]
-- NOTE: now a nvim default

-- Goto tabs Alt-a/z
vim.cmd[[nnoremap <M-a> gT]]
vim.cmd[[nnoremap <M-z> gt]]
vim.cmd[[inoremap <M-a> <esc>gT]]
vim.cmd[[inoremap <M-z> <esc>gt]]

-- Move tabs (with Shift + goto keys)
vim.cmd[[nnoremap <silent> <M-A> :tabmove -1<cr>]]
vim.cmd[[nnoremap <silent> <M-Z> :tabmove +1<cr>]]
vim.cmd[[inoremap <silent> <M-A> <esc>:tabmove -1<cr>]]
vim.cmd[[inoremap <silent> <M-Z> <esc>:tabmove +1<cr>]]

-- Open current buffer in new tab (in a new window)
vim.cmd[[nnoremap <silent> <M-t> :tab split<cr>]]
-- Move current window to new tab
vim.cmd[[nnoremap <silent> <M-T> <C-w>T]]


-- N,I: Insert empty lines below or above
vim.cmd[[inoremap <M-o> <C-o>o]]
vim.cmd[[inoremap <M-O> <C-o>O]]
vim.cmd[[nnoremap <M-o> o<esc>]]
vim.cmd[[nnoremap <M-O> O<esc>]]
-- IDEA: change the semantic a little, to say: 'insert empty line with same context as cursor'
-- * This could be used to insert a line when inside inline func params, and automatically convert
--   the func params to multiline and start a new line.
-- * This would also make possible to change 'o' to 'insert blank line, no care for context', and
--   'M-o' to 'insert line but take care of context' (e.g: stay in comment if currently in comment)
--   normal mode 'M-o' would no longer stay in normal mode, but it's still repeatable since 'M-o' in
--   insert mode do the same.
--   And I can already save from insert mode.. BUT if I just want to add few lines and then move
--   around, i'll have to go back to normal mode myself before.. (acceptable?)
--
-- And we could extend this further, o/O are for entire lines, what about inside a line?
-- * M-i/a could add in same context (container?) before/after current node
--   Like for a function call: foo(1, 2|, 3)
--        `<M-i>new` could be: foo(1, new|, 2, 3)
--        `<M-a>new` could be: foo(1, 2, new|, 3)
--   But could also work for a multiline Lua table!
--
-- * M-I/A could add in same context (container?) at the beginning/end ?
--   Like for a function call: foo(1, 2|, 3)
--        `<M-i>new` could be: foo(new|, 1, 2, 3)
--        `<M-a>new` could be: foo(1, 2, 3, new|)
--   But could also work for a multiline Lua table!
--
-- * M-n/p (?) could move to (begin? of) next/prev sibling nodes
--
-- And then there could be subtle highlights, or statusline segment
-- to show the current inline/line contexts?
-- There could be a interactive mode (a 'submode' of visual mode?) to choose context
-- precisely, where only context-aware keys work?
--
-- And then it should be repeatable!
-- (in another location with same (similar?) context around the cursor)
--
-- ------
-- IDEA: A bit in the same vein as context-add stuff,
-- I'd like to have a way to split a line UP, so:
-- ```
-- some text |-- some comment
-- ```
-- Then `<M-Enter>`, should give:
-- ```
-- |-- some comment
-- some text
-- ```
--
-- Could it be a special case of visual mode `<M-O>` ?
-- That would be a `move selection to same context above/below` (can be repeated)


-- I: Short navigation on the line in insert mode
--
-- This makes it possible to use the cursor keys in Insert mode, without breaking
-- the undo sequence, therefore using `.` (redo) will work as expected.
vim.cmd[[inoremap <Left>  <C-g>U<Left>]]
vim.cmd[[inoremap <Right> <C-g>U<Right>]]
vim.cmd[[inoremap <M-h>   <C-g>U<Left>]]
vim.cmd[[inoremap <M-l>   <C-g>U<Right>]]
-- Move back/forward by word, I'm too used to it in the shell and nvim's
-- cmdline!
vim.cmd[[inoremap <M-b> <C-g>U<S-Left>]]
vim.cmd[[inoremap <M-w> <C-g>U<S-Right>]]


-- Survival keybindings - Command mode

-- C: Cursor movement
toplevel_map{mode="c", key="<M-h>", action="<Left>",    desc="move left"}
toplevel_map{mode="c", key="<M-l>", action="<Right>",   desc="move right"}
toplevel_map{mode="c", key="<M-w>", action="<S-Right>", desc="move to next word"}
toplevel_map{mode="c", key="<M-b>", action="<S-Left>",  desc="move to prev word"}
toplevel_map{mode="c", key="<M-$>", action="<End>",     desc="move to end"}
toplevel_map{mode="c", key="<M-^>", action="<Home>",    desc="move to start"}

-- C: Command history by prefix
toplevel_map{mode="c", key="<M-k>", action="<Up>",      desc="prev history byprefix"}
toplevel_map{mode="c", key="<M-j>", action="<Down>",    desc="next history byprefix"}
-- Command history
toplevel_map{mode="c", key="<M-K>", action="<S-Up>",    desc="prev history"}
toplevel_map{mode="c", key="<M-J>", action="<S-Down>",  desc="next history"}

-- C: Expand %% to dir of current file
-- vim.cmd[[cnoremap <expr> %%  expand("%:.:h") . "/"]]
toplevel_map{mode="c", key="%%", opts={expr=true}, desc="current file's dir", action=function()
  return vim.fn.expand("%:.:h") .. "/"
end}

-- N: toggle wrap
vim.cmd[[nnoremap <silent> <M-w> :set wrap! wrap?<cr>]]


-- Copy/Paste with system clipboard (using nvim's clipboard provider)
-- Register '+' is session clipboard (e.g: tmux)
-- Register '*' is OS/system clipboard
vim.g.clipboard = {
  name = "my-cli-clipboard-provider",
  copy = {
     ["+"] = "cli-clipboard-provider copy-to smart-session",
     ["*"] = "cli-clipboard-provider copy-to system",
   },
  paste = {
     ["+"] = "cli-clipboard-provider paste-from smart-session",
     ["*"] = "cli-clipboard-provider paste-from system",
  },
}

-- Copy
vim.cmd[[xnoremap <silent> <M-c> "+y :echo "Copied to session clipboard!"<cr>]]
vim.cmd[[xnoremap <silent> <M-C> "*y :echo "Copied to system clipboard!"<cr>]]

-- Paste
vim.cmd[[nnoremap <M-v> "+p]]
vim.cmd[[nnoremap <M-V> o<esc>"+p]]
vim.cmd[[xnoremap <M-v> "+p]]
vim.cmd[[cnoremap <M-v> <C-r><C-o>+]]
-- Paste in insert mode inserts an undo breakpoint
-- C-r C-o {reg}    -- inserts the reg content literaly
vim.cmd[[inoremap <silent> <M-v> <C-g>u<C-r><C-o>+]]


--------------------------------

-- toggle relativenumber
--nnoremap <silent> <M-r> :set relativenumber! relativenumber?<cr>

-- Start interactive EasyAlign in visual mode (e.g. vipgea)
--xmap gea <Plug>(EasyAlign)

-- Start interactive EasyAlign for a motion/text object (e.g. geaip)
--nmap gea <Plug>(EasyAlign)

--nnoremap <silent> <C-Space> :CtrlSpace<cr>

-- Toggle terminal
--nnoremap <silent> <C-t> <cmd>FloatermToggle<cr>
--tnoremap <silent> <C-t> <cmd>FloatermToggle<cr>
-- New/next/prev terminal
-- NOTE: I don't plan to use these much, tmux is prefered if I need 2+ terminals
--nnoremap <silent> <C-M-t><C-M-t> <cmd>FloatermNew<cr>
--tnoremap <silent> <C-M-t><C-M-t> <cmd>FloatermNew<cr>
--nnoremap <silent> <C-M-t><C-M-n> <cmd>FloatermNext<cr>
--tnoremap <silent> <C-M-t><C-M-n> <cmd>FloatermNext<cr>
--nnoremap <silent> <C-M-t><C-M-p> <cmd>FloatermPrev<cr>
--tnoremap <silent> <C-M-t><C-M-p> <cmd>FloatermPrev<cr>

---- Navigation
--------------------------------------------------------------------

-- N: Side-scroll using Alt+ScrollWheel
--nmap <M-ScrollWheelUp> zhzhzh
--nmap <M-ScrollWheelDown> zlzlzl

-- Insert helper, useful for most languages so I make it global!
--
-- I: Alt-, to insert a comma after cursor.
-- * When the cursor is at EOL, inserts only ','
-- * When the cursor is in text, inserts ', '
--inoremap <expr> <M-,> (col(".") == col("$") ? ',<C-g>U<Left>' : ', <C-g>U<Left><C-g>U<Left>')

-- Window splits
-- FIXME: now I need repeat mode supports, like in tmux!!
--        similar to Hydra plugin in emacs: https://github.com/abo-abo/hydra
--nnoremap <C-w><C-h>   <cmd>call DirectionalSplit("left")<cr>
--nnoremap <C-w><C-j>   <cmd>call DirectionalSplit("down")<cr>
--nnoremap <C-w><C-k>   <cmd>call DirectionalSplit("up")<cr>
--nnoremap <C-w><C-l>   <cmd>call DirectionalSplit("right")<cr>
--function! DirectionalSplit(dir)
--  let save_split_options = [&splitright, &splitbelow]
--  if a:dir == "left"
--    set nosplitright
--    vsplit
--  elseif a:dir == "down"
--    set splitbelow
--    split
--  elseif a:dir == "up"
--    set nosplitbelow
--    split
--  elseif a:dir == "right"
--    set splitright
--    vsplit
--  endif
--  let &splitright = save_split_options[0]
--  let &splitbelow = save_split_options[1]
--endf

-- Full-width/height window splits
-- FIXME: Do I need this? Would I use this?
-- FIXME: Since I use noequalalways, the created splits takes way too much space...
--   => Maybe get current screen size and make the new one third of that?
--nnoremap <C-M-w><C-M-h>   <cmd> split<cr><C-w>H
--nnoremap <C-M-w><C-M-j>   <cmd>vsplit<cr><C-w>J
--nnoremap <C-M-w><C-M-k>   <cmd>vsplit<cr><C-w>K
--nnoremap <C-M-w><C-M-l>   <cmd> split<cr><C-w>L

-- Smart window split (based on current window size)
--nnoremap <C-w><C-s>  <cmd>call SmartSplit()<cr>
--function! SmartSplit()
--  " ((win_width / 3) > win_height) ? vsplit : split
--  if (winwidth(0) / 3) > winheight(0)
--    call DirectionalSplit("left")
--  else
--    call DirectionalSplit("up")
--  endif
--endf

-- Keep a mapping for original <C-w> behavior
--nnoremap <C-w><C-w>  <cmd>echo "Original ^W behavior..."<cr><C-w>

-- NOTE: Keys still available (not used often / ever)
-- * <C-M-hjkl>
-- * <C-w><C-HJKL>
-- * <C-w><C-M-hjkl>
--
-- TODO: window actions ideas:
-- -> Keys to move current buffer around in the visible (non-float, non-special) windows
-- -> (??) Keys to create a full-width/height BUT do not switch to it


-- CrazyIDEA: Map Alt-MouseClick to resize a window by finding nearest edge??

-- Close tab Alt-d (with confirmation)
--nnoremap <silent> <M-d> :call <SID>TabCloseWithConfirmation()<cr>
--function! s:TabCloseWithConfirmation()
--  if len(gettabinfo()) == 1
--    echo "Cannot close last tab"
--    return
--  endif
--  let choice = confirm("Close tab?", "&Yes\n&Cancel", 0)
--  redraw " clear cmdline, remove the confirm prompt
--  if choice == 1   " Yes
--    tabclose
--  else
--    echo "Close tab cancelled"
--  endif
--endf

-- Toggle zoom on current window
-- From justinmk' config https://github.com/justinmk/config/blob/a93dc73fafbdeb583ce177a9d4ebbbdfaa2d17af/.config/nvim/init.vim#L880-L894
--function! s:zoom_toggle()
--  if 1 == winnr('$')
--    " There is only one window
--    echo "No need to zoom!"
--    return
--  endif

--  if exists('t:zoom_restore')
--    " Restore tab layout
--    let status = "restored"
--    exe t:zoom_restore
--    unlet t:zoom_restore
--  else
--    " Save tab layout & zoom window
--    let status = "saved and window zoomed"
--    let t:zoom_restore = winrestcmd()
--    wincmd |
--    wincmd _
--  endif

--  echo "Tab layout: " . status
--endfunction
--nnoremap <silent> +  :call <SID>zoom_toggle()<cr>

-- Default <C-w>o is dangerous for the layout, hide it behind <C-w>O (maj o)
-- Make it zoom instead (saves the layout for restore)
-- TODO: investigate why <C-w>o mapping does not seem to be overriden...
-- nnoremap <silent> <C-w>o  :call <SID>zoom_toggle()<cr>
-- nnoremap <silent> <C-w>O  :call <C-w>o<cr>


-- V: Move a selection of text
-- Indent/Dedent
--vnoremap <Left>  <gv
--vnoremap <Right> >gv
-- Move Up/Down
-- TODO: make it work with v:count ?
--vnoremap <silent> <Up>   :move '<-2<cr>gv
--vnoremap <silent> <Down> :move '>+1<cr>gv


-- I: M-Space <-- [] --> Space
--
-- <Space>: add space to the left of cursor:    ab[c]d -> ab [c]d
-- <M-Space>: add space to the right of cursor: ab[c]d -> ab[ ]cd
-- Note: <C-G>U is used to avoid breaking the undo sequence on cursor movement
-- meaning that we can repeat (with .) a change that includes a cursor
-- movement.
--inoremap <expr> <M-Space> ' <C-G>U<Left>'

-- I: Alt-Backspace to delete last word (like in most other programs)
--inoremap <M-BS> <C-w>
--cnoremap <M-BS> <C-w>

-- N: Move cursor to begin/end of displayed line (useful when text wraps)
--nnoremap <M-$> g$
--nnoremap <M-^> g^
-- I: Move cursor to begin/end of line
--inoremap <M-$> <C-g>U<End>
-- FIXME: <M-^> is waiting on https://github.com/wez/wezterm/issues/877 to work instantly...
-- FIXME: <Home> moves like 0 not like ^
--inoremap <M-^> <C-g>U<Home>
-- TODO: for <M-^> mappings, support both ^ (first) & 0 (second) (like vscode)
-- TODO: Add <M-b> & <M-w> BUT the movement should stay on the same line!

-- Insert a new line below using <cr>, useful in comments when `formatoptions`
-- has `r` (to auto-add comment start char on <cr> but not o/O) and the cursor
-- is not at eol.
--inoremap <M-cr> <C-o>A<cr>
-- Also works in normal mode, goes in insert mode with a leading comment.
--nnoremap <M-cr> A<cr>

-- Trigger completion manually
--inoremap <silent><expr> <C-b>  (pumvisible() ?
--    \ deoplete#complete_common_string() :
--    \ deoplete#manual_complete())


-- Exit the terminal grabber
--tnoremap <M-Esc> <C-\><C-n>
--tmap  <M-Esc>

-- Indent/Format lines/file
-- I: Indent line, stay in insert mode (default, see :h i_CTRL-F)
--inoremap <C-f> <C-f>
-- V: Indent visual selection, back to normal mode
--vnoremap <C-f> =
-- N: Indent current line
--nnoremap <C-f> mi==`i
-- N: Format the entire file
--nnoremap <M-C-f> gg=G``

-- N: un-join (split) the current line at the cursor position
--nnoremap <M-J> i<c-j><esc>k$

-- Copy absolute filepath
--nnoremap <silent> y%% :let @" = expand("%:p") \| echo "File path copied (" . @" . ")"<cr>

-- V: logical visual eol
-- For some reason in visual mode '$' goes beyond end of line and include the newline,
-- making 'v$d' (or other actions) delete the end of line + the newline, joining them without being smart about it..
--   => Totally not what I wanted... Let's fix this!
-- NOTE1: Repeating with '.' from normal mode doesn't work (it's not better without this mapping so..)
-- NOTE2: Need to check the mode, as in visual block '$h' disables the smart 'to-the-end' selection.
--vnoremap <expr> $ (mode() == "v" ? "$h" : "$")

-- N: Select last inserted region
--nnoremap gV `[v`]
-- O: Textobj for the last inserted region
--onoremap gV <cmd>normal! `[v`]<cr>

-- Vim eval-and-replace:
-- Evaluate the current selection as a vimscript expression and replace
-- the selection with the result
-- NOTE1: changes the unnamed register
-- NOTE2: <C-r><C-r>{register} takes the register content verbatim
--   (whereas <C-r> inserts the register content as if typed)
--vnoremap <Plug>(my-EvalAndReplaceVimExpr-visual) c<C-r>=<C-r><C-r>"<cr><esc>

-- Vim eval-as-ex:
-- Run the current line/selection as an EX command
-- NOTE: changes the unnamed register
--function! ExecuteAsExFromUnnamed(what)
--  let l:splitted_reg = split(@", "\n")
--  execute @"
--  let num_lines = len(l:splitted_reg)
--  if num_lines <= 1
--    let lines_text = num_lines . " line"
--  else
--    let lines_text = num_lines . " lines"
--  endif
--  echom "Sourced " . a:what . "! (" . lines_text . ")"
--endf
--nnoremap <Plug>(my-ExecuteAsVimEx-normal) yy:call ExecuteAsExFromUnnamed("current line")<cr>
--vnoremap <Plug>(my-ExecuteAsVimEx-visual) y:call ExecuteAsExFromUnnamed("visual selection")<cr>gv
--nnoremap <Plug>(my-ExecuteAsVimEx-full-file) <cmd>source % <bar> echo "Sourced current file! (" . line("$") . " lines)"<cr>

-- Search with{,out} word boundaries
-- V: search selection with word boundaries
--vmap * <Plug>(visualstar-*)
-- V: search selection without word boundaries
--vmap <M-*> <Plug>(visualstar-g*)
-- N: search current word without word boundaries
--nnoremap <M-*> g*

--vnoremap <M-p> <cmd>call VisualPaste()<cr>
-- Visual paste with the current register, preserving the content of
-- the unnamed register.
--function! VisualPaste()
--  " Save unnamed register (will be overwritten with the normal visual paste)
--  let save_reg = getreg('"', 1, v:true)
--  let save_regtype = getregtype('"')
--
--  exe 'normal! "' . v:register . 'p'
--
--  " Restore unnamed register
--  call setreg('"', save_reg, save_regtype)
--endfunction

-- Inspired from visual-at.vim from Practical Vim 2nd Edition
--vnoremap <silent> @ :<C-u>call ExecuteMacroOverVisualRange()<cr>
--function! ExecuteMacroOverVisualRange()
--  let register = nr2char(getchar())
--  if register == "" " this is the ^[ (esc) char
--    return
--  endif
--  if visualmode() == ""  " this is the ^V char
--    let column_code = getpos("'<")[2] . "|"
--  else
--    let column_code = ""
--  endif
--  execute ":'<,'>normal! " . column_code . "@" . register
--endfunction

-- V: Record a macro on first line, and repeat it on all other selected lines
-- This is the poor-man multiselection... (not even interactive)
-- NOTE: Maybe I'll never use it as I can also record macro then apply with @reg..
--       I don't know, but it was interesting to do!
--vnoremap qq :<C-u>call <SID>StartRecordMacroForVisualRange()<cr>
--function! <SID>StartRecordMacroForVisualRange()
--  " Save visual selection, in case the macro makes use of visual selection
--  " return format is [_bufnum, lnum, col, _off]
--  let b:macro_visual_start = getpos("'<")
--  let b:macro_visual_end = getpos("'>")
--  let b:macro_visual_is_vblock = visualmode() == ""  " this is the ^V char
--  call setpos(".", b:macro_visual_start)
--  " TODO: Highlight saved visual selection (in IncSearch hi for example?)
--  "       while recording the macro.
--  nnoremap <buffer> q  <cmd>call <SID>ExecutePendingMacroOverSavedVisualRange()<cr>
--  " Start recording...
--  normal! qq
--endf
--function! <SID>ExecutePendingMacroOverSavedVisualRange()
--  " Unmap q, was <buffer> mapped in StartRecordMacroForVisualRange
--  nunmap <buffer> q
--  " End recording, started in StartRecordMacroForVisualRange
--  normal! q
--
--  if getreg("q") == ""
--    return
--  endif
--
--  let start_next_line = b:macro_visual_start[1] + 1
--  let end_line = b:macro_visual_end[1]
--  if b:macro_visual_is_vblock
--    let column_code = b:macro_visual_start[2] . "|"
--  else
--    let column_code = ""
--  endif
--
--  " Format as `:START,END normal! COL|@q`
--  let cmd = ":" . start_next_line . "," . end_line . "normal! " . column_code . "@q"
--  " echom cmd
--  execute cmd
--
--  let save_final_pos = getpos(".")
--
--  " Restore visual selection to be same as before batch action (including vblock)
--  call setpos("'<", b:macro_visual_start)
--  call setpos("'>", b:macro_visual_end)
--  if b:macro_visual_is_vblock
--    " Re-enter visual block temporarily to mark this visual selection as block..
--    " FIXME: is there a better way?
--    execute "normal! gv"
--  endif
--  call setpos(".", save_final_pos)
--
--  unlet b:macro_visual_start
--  unlet b:macro_visual_end
--  unlet b:macro_visual_is_vblock
--endf

-- Toggles signcolumn, number & relativenumber at once
--function! ToggleSignsAndLineNumbers()
--  if exists('w:saved_signs_and_linenum_options')
--    let status = "restored"
--
--    " Restore saved option values
--    let &signcolumn = w:saved_signs_and_linenum_options['signcolumn']
--    let &number = w:saved_signs_and_linenum_options['number']
--    let &relativenumber = w:saved_signs_and_linenum_options['relativenumber']
--
--    if w:saved_signs_and_linenum_options["indentLine_enabled"]
--      IndentLinesEnable
--    endif
--
--    unlet w:saved_signs_and_linenum_options
--  else
--    let status = "saved & disabled"
--
--    " Save options and disable them
--    let w:saved_signs_and_linenum_options = {
--        \ 'signcolumn': &signcolumn,
--        \ 'number': &number,
--        \ 'relativenumber': &relativenumber,
--        \ }
--    if exists("b:indentLine_enabled")
--      " If the buffer local var exists, g:indentLine_enabled should not be checked
--      " (it's always 1, even when disabled locally)
--      let w:saved_signs_and_linenum_options.indentLine_enabled = b:indentLine_enabled
--    else
--      let w:saved_signs_and_linenum_options.indentLine_enabled = g:indentLine_enabled
--    endif
--    let &signcolumn = "no"
--    let &number = 0
--    let &relativenumber = 0
--    IndentLinesDisable
--  endif
--
--  echo "Signs and line numbers: " . l:status
--endf
--nnoremap <M-R>  <cmd>call ToggleSignsAndLineNumbers()<cr>

-- Fold ranged open/close
-- NOTE: this does not change the 'foldlevel'.
-- FIXME: these mappings must be typed fast, otherwise you get normal behavior.
-- Make sure to read `:h fold-commands` for all the details.
-- open all folds in range
--vnoremap <silent> zo  :<C-u>'<,'>foldopen!<cr>
-- close all manually opened folds in range
--vnoremap <silent> zc  zx

-- Duplicate the visual selection
--vnoremap <C-d> <cmd>call <sid>DuplicateVisualSelection()<cr>
--function! s:DuplicateVisualSelection()
--  " Save unnamed register (will be overwritten when copying current visual selection)
--  let save_reg = getreg('"', 1, v:true)
--  let save_regtype = getregtype('"')

--  " Copy, go to the end of the selection, paste
--  exe 'normal! y`>p'

--  " Restore unnamed register
--  call setreg('"', save_reg, save_regtype)
--endf

-- Toggle Mundo tree
--nnoremap <silent> <F5> :MundoToggle<cr>

-- Open or focus NERDTree window
--nnoremap <silent> <F6> :call NERDTreeFocus()<cr>
-- Note: Shift-F6 is F16 (on urxvt)
--nnoremap <silent> <F16> :NERDTreeFind<cr>

-- Show highlight infos
--function! s:syntax_query(verbose) abort
--  if a:verbose == v:true
--    let cmd = "verbose hi"
--  else
--    let cmd = "hi"
--  endif

--  echo "--- Syntax stack at line:" . line(".") . " col:" . col(".") . " ---"
--  for id in synstack(line("."), col("."))
--    execute cmd synIDattr(id, "name")
--  endfor
--endfunction
--nnoremap <silent> <F2> :call <SID>syntax_query(v:false)<cr>
--nnoremap <silent> <F3> :call <SID>syntax_query(v:true)<cr>

-- ---- Command mode

-- Save the file as sudo
--cnoremap w!! w !env SUDO_ASKPASS=$HOME/.bin-gui/zenity_passwd.sh sudo tee % >/dev/null


-- ---- Various Leader key mappings ----
-- (NOTE: some mappings are in init.vim)
--
-- Nice example of mappings! (https://github.com/phaazon/config/blob/ea8378065/nvim/key_bindings.vim)

-- -- Vim
--nmap <leader>vs <Plug>(my-ExecuteAsVimEx-full-file)
--nmap <leader>vx <Plug>(my-ExecuteAsVimEx-normal)
--vmap <leader>vx <Plug>(my-ExecuteAsVimEx-visual)
--lua wk_leader_n_maps.v = {name = "+vim"}
--lua wk_leader_v_maps.v = {name = "+vim"}
--lua wk_leader_n_maps.v.s = "source current file"
--lua wk_leader_n_maps.v.x = "exec current line as VimEx"
--lua wk_leader_v_maps.v.x = "exec selection as VimEx"
--nmap <leader>ve gv<Plug>(my-EvalAndReplaceVimExpr-visual)
--vmap <leader>ve   <Plug>(my-EvalAndReplaceVimExpr-visual)
--lua wk_leader_n_maps.v.e = "eval-n-replace selection as vim expr"
--lua wk_leader_v_maps.v.e = "eval-n-replace selection as vim expr"

-- -- Code
--lua wk_leader_n_maps.c = {name = "+code"}
--lua wk_leader_v_maps.c = {name = "+code"}

-- code language tools
-- FIXME: These should be buffer-local maps
--nmap <leader>c²   <Plug>(lcn-menu)
--nmap <leader>cd   <Plug>(lcn-definition)
--nmap <leader>ct   <Plug>(lcn-type-definition)
--nmap <leader>cu   <Plug>(lcn-references)
--nmap <leader>cr   <Plug>(lcn-rename)
--nmap <leader>ca   <Plug>(lcn-code-action)
--nmap <leader>ci   <Plug>(lcn-implementation)
--nmap <leader>ch   <Plug>(lcn-hover)
--nmap <leader>c<space>   <Plug>(lcn-hover)
--lua wk_leader_n_maps.c["²"] = "lang menu"
--lua wk_leader_n_maps.c.d = "lang goto def"
--lua wk_leader_n_maps.c.t = "lang goto type"
--lua wk_leader_n_maps.c.u = "lang usages/references"
--lua wk_leader_n_maps.c.r = "lang rename"
--lua wk_leader_n_maps.c.a = "lang code actions"
--lua wk_leader_n_maps.c.i = "lang implementation"
--lua wk_leader_n_maps.c.h = "lang hover info"
--lua wk_leader_n_maps.c["<space>"] = "lang hover info"
-- Additional keys, which should be better defined..
-- TODO: Use virtual keys!
--nmap ²   <Plug>(lcn-hover)
-- TODO: nmap K   <please always give documentation in an upper split>

-- TODO: Setup virtual keys for language tools/actions (with default msg),
--   and enable for python (jedi) and when the language client is active

-- code/content context (using context.vim plugin)
--nmap <Leader>cx   <cmd>MyContextPeek<cr>
--lua wk_leader_n_maps.c.x = "context peek (until move)"

-- -- Quickfix / Location lists
--lua wk_leader_n_maps["!"] = {name = "+qf-loc-list"}
--nmap <leader>!c   <cmd>lclose \| copen<cr>
--nmap <leader>!l   <cmd>cclose \| lopen<cr>
--nmap <leader>!!   <cmd>call <SID>OnLastQfLocListDoTryNextOrFirst()<cr>
--lua wk_leader_n_maps["!"].c = "open qf list (global)"
--lua wk_leader_n_maps["!"].l = "open loc list (local)"
--lua wk_leader_n_maps["!"]["!"] = "jump to next/first in last list"

-- Try to detect the qf or loc list, and save which one is the last one
--function! s:TryRegisterLastUsedQfOrLocList()
--  let wininfo = getwininfo(win_getid())[0]
--  " let r = getwininfo(win_getid())[0] | echo "qf: " . r.quickfix . " loc: " . r.loclist
--  let is_qf_list = (wininfo.quickfix && !wininfo.loclist)  " qf: 1 && loc: 0
--  let is_loc_list = (wininfo.quickfix && wininfo.loclist)  " qf: 1 && loc: 1
--  if is_qf_list
--    let w:last_used_qf_or_loc_list = "qf"
--  elseif is_loc_list
--    let w:last_used_qf_or_loc_list = "loc"
--  else
--    " Do nothing, leave the current value as is.
--  endif
--endf
--augroup my_detect_last_used_qf_loc_list
--  au!
--  " Init the win variable on each new win
--  autocmd VimEnter,WinNew * let w:last_used_qf_or_loc_list = get(w:, "last_used_qf_or_loc_list", "none")
--  " Try to detect the qf or loc list, and save which one is the last one
--  autocmd BufWinEnter * call <SID>TryRegisterLastUsedQfOrLocList()
--augroup END
--function! s:OnLastQfLocListDoTryNextOrFirst()
--  let qf_cmds = {"name": "qf", "action_next": "cnext", "action_first": "cfirst"}
--  let loc_cmds = {"name": "loc", "action_next": "lnext", "action_first": "lfirst"}
--  if w:last_used_qf_or_loc_list == "qf"
--    let cmds = qf_cmds
--  elseif w:last_used_qf_or_loc_list == "loc"
--    let cmds = loc_cmds
--  else
--    " Default to the location list
--    let cmds = loc_cmds
--  endif

--  try
--    " echo "[". cmds.name ." list] trying next: ". cmds.action_next
--    execute cmds.action_next
--  catch
--    try
--      " echo "[". cmds.name ." list] nop.. trying first: ". cmds.action_first
--      execute cmds.action_first
--    catch
--      echo "[". cmds.name ." list] nope, it's empty!"
--    endtry
--  endtry
--endf

-- -- Edit
-- Use this to make a few nice mappings
-- Taken from: http://vimcasts.org/episodes/the-edit-command/
--lua <<LUA
--leader_map_define_group{mode={"n"}, prefix_key="e", name="+relative-edit"}
---- note: remap needed for '%%' to trigger!
--leader_remap{mode={"n"}, key="ee", action=":e %%",      desc="here"}
--leader_remap{mode={"n"}, key="es", action=":split %%",  desc="in split"}
--leader_remap{mode={"n"}, key="ev", action=":vsplit %%", desc="in v' split"}
--leader_remap{mode={"n"}, key="et", action=":tabe %%",   desc="in tab"}
--LUA

-- -----------------
-- IDEAS: (from vscode)
-- M-Up/Down -> Move current line (or range) up/down, following indentations
-- M-S-Up/Down -> Copy current line Up/Down
-- M-S-Left/Right -> Shrink/Expand (char-)selection (can be simulated in vim?
--     even without proper language support/detection?)
--
-- IDEA: Add mapping (<leader>vr ? or <M-C-R> ?) to reload file HUD info like the diagnostics,
-- the git signs, python's semantic highlights
-- (if possible, without reloading buffer from disk with :e)
