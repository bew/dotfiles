-- VIM - mappings
-- --------------------------------------------------------------------
-- 'I speak vim' - bew, 2021

local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

-- TODO: Add tags! Define layers! (& group of related keys?)

-- Disable keybindings

my_actions.disabled = mk_action_v2 {
  [{"n", "i", "v", "c"}] = "<nop>"
}

-- <C-LeftMouse> default to <C-]>, which just give errors in most files..
-- I may re-enable it in a smart way whenever I really want it!
toplevel_map{mode="n", key="<C-LeftMouse>", action=my_actions.disabled}

-- I: Disable up/down keys
--
-- This is required to disable scrolling in insert mode when running under tmux with scrolling
-- emulation mouse bindings for the alternate screen, because it would move Up/Down N times based on
-- the scrolling emulation config.
toplevel_map{mode="i", key=[[<Up>]], action=my_actions.disabled}
toplevel_map{mode="i", key=[[<Down>]], action=my_actions.disabled}

-- N: Disable some builtin keys around goto def/decl (I use other mappings anyway)
toplevel_map{mode="n", key="gd", action=my_actions.disabled}
toplevel_map{mode="n", key="gD", action=my_actions.disabled}

----- Survival keybindings..

-- N,I,V: Save buffer
-- NOTE: using lockmarks to avoid overwriting '[ & '] marks by the 'write'
--   See: https://neovim.discourse.group/t/using-after-w/3608
my_actions.save_buffer = mk_action_v2 {
  default_desc = "Save buffer",
  [{"n", "i", "v"}] = [[<esc><cmd>lockmarks write<cr>]],
  map_opts = { silent = true },
}
toplevel_map{mode={"n", "i", "v"}, key=[[<M-s>]], action=my_actions.save_buffer}

-- N: Quit window
my_actions.close_window = mk_action_v2 {
  default_desc = "Close window",
  n = [[<cmd>quit<cr>]],
  map_opts = { silent = true },
}
toplevel_map{mode="n", key="Q", action=my_actions.close_window}
-- <wm-mappings>
global_leader_map{mode="n", key="<C-M-d>", action=my_actions.close_window}


-- N: logical redo
my_actions.undo = mk_action_v2 {
  default_desc = "Undo",
  n = [[u]],
}
my_actions.redo = mk_action_v2 {
  default_desc = "Redo",
  n = [[<C-r>]],
}
toplevel_map{mode="n", key="u", action=my_actions.undo}
toplevel_map{mode="n", key="U", action=my_actions.redo}

-- N: Y to copy whole line
my_actions.copy_line = mk_action_v2 {
  default_desc = "Copy line",
  n = "yy",
}
toplevel_map{mode="n", key="Y", action=my_actions.copy_line}

-- N: Discard last search highlight
my_actions.hide_search_hl = mk_action_v2 {
  default_desc="Hide search highlight",
  n = function()
    vim.cmd[[nohlsearch]]
    -- IDEA: disappear after 1s ?
    vim.notify "Search cleared"
  end,
}
toplevel_map{mode="n", key="§",     action=my_actions.hide_search_hl}
-- FIXME: Investigate why outside of tmux, nvim recognizes '§' as '<S-§>'..
--   In the meantime let's bind both :shrug:
toplevel_map{mode="n", key="<S-§>", action=my_actions.hide_search_hl}

-- NOTE: Configurable actions are not ready yet at all..
--   Let's still keep the spec written down, and use the functions directly in mappings
-- IDEA: alt action definition interface:
-- mk_configurable_action(function(act)
--   local function foo() end
--   act.options.bounded = ...
--   act.default_desc = ...
--   act.mode.n = ... -- (use local function 'foo'…)
--   act.mode.n.default_desc = ...
-- end)
--
-- Search current word/selection (without moving the cursor)
-- (initially inspired from https://github.com/neovim/neovim/discussions/24285)
-- => IDEA(later): Package as a plugin (with optional action) for others?
my_actions.hlsearch_current = {
  default_desc = function(self)
    -- IDEA: could make a templating system to be able to write dynamic doc like:
    --   `Search current {x.mode==n:word}{x.mode==v:selection}` (+ if/else for extra)
    if self.ctx.mode == "n" then
      doc = "Search current word"
    end
    if self.ctx.mode == "v" then
      doc = "Search current selection"
    end
    if self.ctx.mode == "v" and self.opts.word_bounds then
      -- Bounds are 'smart' in visual mode as we inspect selection surrounding chars to put bounds
      -- only where it makes sense.
      doc = doc .. " (with smart bounds)"
    elseif self.opts.word_bounds then
      doc = doc .. " (with bounds)"
    else
      doc = doc .. " (unbounded)"
    end
    return doc
  end,
  options = {
    -- IDEA for other names: word_bounds, with_bounds, with_word_bounds
    word_bounds = mk_action_opt{
      desc = [[Whether the search should be bounded (true) or anywhere (false) (in visual mode, bounds are guessed to best match selection)]],
      type = "boolean", -- nicer: `t.bool`
      default = false,
    },
    embed_cursor_pos_in_search = mk_action_opt{ -- TODO: impl this!
      desc = [[Whether to embed cursor position in search, to keep the current offset for all matches]],
      type = "boolean", -- nicer: `t.bool`
      default = false,
    },
    -- TODO: currently always as if `true`, need to impl `false`
    -- GOTCHA: if this is false, `embed_cursor_pos_in_search` cannot be `true` 👀
    -- FIXME: => does it even make sense to have a separate option for this?
    --   => Might be better to merge `embed_cursor_pos_in_search` & `preserve_cursor_pos` ?
    -- preserve_cursor_pos = mk_action_opt{
    --   desc = [[]],
    --   type = "boolean", -- nicer: `t.bool`
    --   default = false,
    -- },
  },
  mode_actions = {
    n = function(self)
      local current_word = vim.fn.expand("<cword>")
      U.set_current_search(current_word, { with_bounds = self.opts.word_bounds })
    end,
    -- IDEA(later): make searching `with` by selecting it in `withFoo` NOT match `without` NOR `with-you`
    -- IDEA(even later): make searching TS-aware, only match positions that have the same TS note type 👀
    --   (would need neovim changes to integrate well with other search builtin actions and plugins
    --   based on them; need to find compelling use-cases to attempt a neovim core change..)
    v = function(self)
      if vim.fn.mode() == "" then
        -- FIXME: what else could I do here? 🤔
        --   Neovim can't make disjoint text searches..
        error("search_current in visual mode does not support visual block")
      end
      local necessary_word_bounds = self.opts.word_bounds
      if self.opts.word_bounds then
        -- Guess required word bounds to best match selected text, with max restrictions.
        -- => This is necessary to ensure the search will AT LEAST match the selected text.
        -- NOTE: If we always add word bounds before/after, it can happen that the selection doesn't
        --   actually start/end on a word bound, and the resulting search doesn't match it..
        local visual_bounds = U.get_visual_start_end_pos0()
        local start_pos0, end_pos0 = visual_bounds.start_pos0, visual_bounds.end_pos0
        local start_char = U.try_get_buf_char_at_pos0(start_pos0)
        local before_start_char = U.try_get_buf_char_at_pos0(start_pos0:with_delta{col = -1})
        local end_char = U.try_get_buf_char_at_pos0(end_pos0)
        local after_end_char = U.try_get_buf_char_at_pos0(end_pos0:with_delta{col = 1})
        necessary_word_bounds = {
          -- A word bound is appropriate when the visual selection starts / ends a keyword
          -- NOTE: Some chars are out of bound in visual line mode
          --   => they'll default to `""` (not a keyword)
          before = U.char_is_keyword(start_char or "") and not U.char_is_keyword(before_start_char or ""),
          after = U.char_is_keyword(end_char or "") and not U.char_is_keyword(after_end_char or ""),
        }
        -- print(_f{
        --   "start_char", vim.inspect(start_char),
        --   "before_start_char", vim.inspect(before_start_char),
        --   "end_char", vim.inspect(end_char),
        --   "after_end_char", vim.inspect(after_end_char),
        --   "word_bounds", vim.inspect{ necessary_word_bounds.before, necessary_word_bounds.after },
        -- })
      end
      local selection_lines = U.get_visual_selection_lines()
      U.set_current_search(selection_lines, { with_bounds = necessary_word_bounds })
    end,
  },
}
-- For when the configurable action is ready:
--toplevel_map{mode={"n", "v"}, key="*", action=my_actions.hlsearch_current:with_opts{word_bounds=true}}
--toplevel_map{mode={"n", "v"}, key="<M-*>", action=my_actions.hlsearch_current}
--
-- NOTE: For now I'm using direct functions, simulating a call by the action system
toplevel_map{mode="n", key="*", desc="Search current word (with bounds)", action=function()
  my_actions.hlsearch_current.mode_actions.n({ opts = { word_bounds = true } })
end}
toplevel_map{mode="v", key="*", desc="Search current selection (with 'smart' bounds)", action=function()
  my_actions.hlsearch_current.mode_actions.v({ opts = { word_bounds = true } })
end}
toplevel_map{mode="n", key="<M-*>", desc="Search current word (unbounded)", action=function()
  my_actions.hlsearch_current.mode_actions.n({ opts = { word_bounds = false } })
end}
toplevel_map{mode="v", key="<M-*>", desc="Search current selection (unbounded)", action=function()
  my_actions.hlsearch_current.mode_actions.v({ opts = { word_bounds = false } })
end}

-- N: Remap n/N to always move in a stable direction
--
-- `n` will always go forward (even after a backward search)
-- `N` will always go backward (even after a forward search)
my_actions.go_next_search_result = mk_action_v2 {
  default_desc = "Goto next search result (always forward)",
  map_opts = { expr = true },
  n = function()
    if vim.v.searchforward == 1 then
      return "n" -- continue forward
    else
      return "N" -- go backward instead
    end
  end,
}
my_actions.go_prev_search_result = mk_action_v2 {
  default_desc = "Goto previous search result (always backward)",
  map_opts = { expr = true },
  n = function()
    if vim.v.searchforward == 1 then
      return "N" -- go forward instead
    else
      return "n" -- continue backward
    end
  end,
}
toplevel_map{mode="n", key="n", action=my_actions.go_next_search_result}
toplevel_map{mode="n", key="N", action=my_actions.go_prev_search_result}

-- Windows navigation
vim.cmd[[nnoremap <C-h> <C-w>h]]
vim.cmd[[nnoremap <C-j> <C-w>j]]
vim.cmd[[nnoremap <C-k> <C-w>k]]
vim.cmd[[nnoremap <C-l> <C-w>l]]
--vim.cmd[[nmap <cr> <C-j>]] -- When mapping <C-j> has no effect
--vim.cmd[[nmap <BS> <C-h>]] -- When mapping <C-h> has no effect

-- Goto tabs Alt-a/z
my_actions.go_prev_tab = mk_action_v2 {
  default_desc = "Go to prev tab",
  [{"n", "i"}] = "<esc>gT",
}
my_actions.go_next_tab = mk_action_v2 {
  default_desc = "Go to next tab",
  [{"n", "i"}] = "<esc>gt",
}
toplevel_map{mode={"n", "i"}, key=[[<M-a>]], action=my_actions.go_prev_tab}
toplevel_map{mode={"n", "i"}, key=[[<M-z>]], action=my_actions.go_next_tab}

-- Move tabs (with Shift + goto keys)
my_actions.move_tab_left = mk_action_v2 {
  default_desc = "Move tab left",
  [{"n", "i"}] = [[<esc><cmd>tabmove -1<cr>]],
  map_opts = { silent = true },
}
my_actions.move_tab_right = mk_action_v2 {
  default_desc = "Move tab right",
  [{"n", "i"}] = [[<esc><cmd>tabmove +1<cr>]],
  map_opts = { silent = true },
}
toplevel_map{mode="n", key=[[<M-A>]], action=my_actions.move_tab_left}
toplevel_map{mode="n", key=[[<M-Z>]], action=my_actions.move_tab_right}

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
--        `<M-I>new` could be: foo(new|, 1, 2, 3)
--        `<M-A>new` could be: foo(1, 2, 3, new|)
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

-- A: Duplicate visual selection
my_actions.duplicate_selection = mk_action_v2 {
  v = function()
    -- NOTE: initially I wanted to implement this using idiomatic Lua APIs..
    -- however Visual selection is a pain to get reliably while handling all cases.
    -- See this PR that attempts to add a vim.get_visual_selection() function:
    --   https://github.com/neovim/neovim/pull/13896
    --
    -- So until we have better APIs to manipulate visual mode, let's just implement it
    -- in a way similar to my old vimscript implementation :shrug:

    U.save_run_restore({ save_registers = {[["]]} }, function()
      local visual_mode = vim.fn.mode()
      if visual_mode == "v" or visual_mode == "V" then
        --- Char or Line selection mode:
        -- Copy, go to the end of the selection, paste
        -- then re-enter visual (for easy repeat)
        vim.fn.execute [[noautocmd normal! y`>p]]
      else
        --- Block selection mode:
        -- Copy (cursor moves to top left of block), paste before
        -- then re-enter visual (for easy repeat)
        --
        -- NOTE: for some reason paste before in block mode does _not_ move
        -- last visual marks.. (they do move when using this in the other visual modes)
        vim.fn.execute [[noautocmd normal! yP]]
      end
    end)
  end,
}
-- V: Duplicate visual selection
toplevel_map{mode="v", key="<C-d>", desc="Duplicate selection", action=my_actions.duplicate_selection}
-- V: Duplicate visual selection (stay in visual mode, can be 'spammed' for repeat)
toplevel_map{mode="v", key="<C-M-d>", desc="Duplicate selection (keep selection)", action=function()
  my_actions.duplicate_selection()
  vim.fn.execute [[noautocmd normal! gv]]
end}
-- IDEA: a mapping to duplicate and comment original selection

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
-- FIXME: there are no way to move to end-of-word from insert mode
-- And if I make a custom mapping it wouldn't be repeatable :/ (FIXME<i-action-not-repeatable>)


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

-- TODO: Make <C-w> delete entire last arg (space separated?)
--   and <M-BS> delete smaller parts (like builtin <C-w>)

my_actions.c_expand_file_path = mk_action_v2 {
  default_desc = "expand current file path",
  map_opts = { expr = true },
  c = function()
    return vim.fn.expand("%:.")
  end,
}
-- C: Expand %P to path of current file
-- (using uppercase P because % also needs shift, so it's easy to 'spam')
toplevel_map{mode="c", key="%P", action=my_actions.c_expand_file_path}

my_actions.c_expand_file_dir = mk_action_v2 {
  default_desc = "expand current file dir",
  map_opts = { expr = true },
  c = function()
    return vim.fn.expand("%:.:h") .. "/"
  end,
}
-- C: Expand %% to dir of current file
toplevel_map{mode="c", key="%%", action=my_actions.c_expand_file_dir}

-- N: toggle wrap
vim.cmd[[nnoremap <silent> <M-w> :set wrap! wrap?<cr>]]
-- N: toggle relativenumber
vim.cmd[[nnoremap <silent> <M-r> :set relativenumber! relativenumber?<cr>]]


-- Copy/Paste with session/system clipboard
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
vim.cmd[[xnoremap <silent> <M-c> "+y<cmd>echo "Copied to session clipboard!"<cr>]]
vim.cmd[[xnoremap <silent> <M-C> "*y<cmd>echo "Copied to system clipboard!"<cr>]]

-- Paste
vim.cmd[[nnoremap <M-v> "+p]]
vim.cmd[[nnoremap <M-V> o<esc>"+p]]
vim.cmd[[xnoremap <M-v> "+p]]
vim.cmd[[cnoremap <M-v> <C-r><C-o>+]]
-- Paste in insert mode inserts an undo breakpoint
-- C-r C-o {reg}    -- inserts the reg content literaly
vim.cmd[[inoremap <silent> <M-v> <C-g>u<C-r><C-o>+]]

--------------------------------
-- Better visual mode support

-- V: logical visual eol
-- For some reason in visual mode '$' goes beyond end of line and include the newline,
-- making 'v$d' (or other actions) delete the end of line + the newline, joining them without being smart about it..
--   => Totally not what I wanted... Let's fix this!
-- NOTE1: Repeating with '.' from normal mode doesn't work (it's not better without this mapping so..)
-- NOTE2: Need to check the mode, as in visual block '$h' disables the smart 'to-the-end' selection.
-- vim.cmd[[ vnoremap <expr> $ (mode() == "v" ? "$h" : "$") ]]
my_actions.logical_visual_eol = mk_action_v2 {
  default_desc = "logical EOL",
  map_opts = { expr = true }, -- inject keys!
  v = function()
    if vim.fn.mode() == "v" then
      return "$h"
    else
      return "$"
    end
  end,
}
toplevel_map{mode="v", key="$", action=my_actions.logical_visual_eol}

my_actions.select_last_inserted_region = mk_action_v2 {
  default_desc = "select last inserted region",
  n = "`[v`]",
}
-- FIXME: how to merge the two normal/operator actions?
my_actions.o_select_last_inserted_region = mk_action_v2 {
  default_desc = "select last inserted region",
  o = [[<cmd>normal! `[v`]<cr>]],
}
-- N: Select last inserted region
toplevel_map{mode="n", key="gV", action=my_actions.select_last_inserted_region}
-- O: Textobj for the last inserted region
toplevel_map{mode="o", key="gV", action=my_actions.o_select_last_inserted_region}

-- TODO: omap `A)` to allow `dA)` to delete parentheses and surrounding spaces.
--   (FIXME: On `foo (bar) baz`, should remove space or after or both? 🤔)
-- TODO: omap `I}` to allow `cI}` to change `foo` on `bla { foo }` (inside braces and spaces)

-- V: Clean paste (preserving the content of the current/unnamed register),
--    so I can paste over multiple visual selections using the same text
toplevel_map{mode="v", key="p", desc="paste (preserves register)", action="P"}
-- V: Vim's visual paste (replacing current/unnamed register)
toplevel_map{mode="v", key="P", desc="paste (swaps register)", action="p"}

-- V: Ranged fold open/close
-- NOTE1: this does not change the 'foldlevel'.
-- NOTE2: these mappings must be typed fast, otherwise you get normal behavior.
-- Make sure to read `:h fold-commands` for all the details.
-- open all folds in range
vim.cmd[[vnoremap <silent> zo  :<C-u>'<,'>foldopen!<cr>]]
-- close all manually opened folds in range
vim.cmd[[vnoremap <silent> zc  zx]]

--------------------------------
-- Insert helpers

-- I,C: Alt-Backspace to delete last word (like in most other programs)
vim.cmd[[imap <M-BS> <C-w>]] -- using imap, for autopairs' auto-delete behavior of <C-w>
vim.cmd[[cnoremap <M-BS> <C-w>]]

-- N: Move cursor to begin/end of displayed line (useful when text wraps)
-- FIXME: conflicts with <M-^> used to smartly move to bol
-- vim.cmd[[nnoremap <M-$> g$]]
-- vim.cmd[[nnoremap <M-^> g^]]

-- I: Move cursor to begin/end of line
-- NOTE: moved to "smart-bol.nvim" plug definition (would prefer to have all here?)
-- Or define as virtual keys that are overriden in plugin definition?

-- TODO: Add <M-b> & <M-w> BUT the movement should stay on the same line! (or same treesitter 'logical line')

-- I: Add space after cursor
--
-- The goal is to have: Space <- | -> M-Space
-- <Space>   inserts space to the left of cursor:  `ab|cd` -> `ab |cd` (usual)
-- <M-Space> inserts space to the right of cursor: `ab|cd` -> `ab| cd`
vim.cmd[[inoremap <M-Space> <Space><C-g>U<Left>]]

-- I: Insert a new line below using <cr> in same context, even when cursor not
-- at eol, useful in comments!
-- NOTE: `formatoptions` needs to have `r`
--   (to auto-add comment start char on <cr>)
vim.cmd[[inoremap <M-cr> <C-o>A<cr>]]
-- N: Same in normal mode, ends in insert mode
--   go in insert mode with a leading comment.
vim.cmd[[nnoremap <M-cr> A<cr>]]

-- I: Alt-, to insert a comma after cursor.
-- * When the cursor is at EOL, inserts only ','
-- * When the cursor is in text, inserts ', '
--
-- => Useful for most languages so make it global!
-- TODO: be smarter based on surrounding text! (even without treesitter)
vim.cmd[[inoremap <expr> <M-,> (col(".") == col("$") ? ',<C-g>U<Left>' : ', <C-g>U<Left><C-g>U<Left>')]]



--------------------------------
-- Window manipulation

-- IDEA of plugin & mapping: Being able to use <C-w>u to undo last window/tab close !eyes

-- LATER: This could be a good candidate for a keymap/layer
--   It can be appended to <C-w> or activated on <C-w> ?
-- LATER: would be nice to have 'repeat' mode supports, like in tmux!!
--   similar to Hydra plugin in emacs: https://github.com/abo-abo/hydra
--   See hydra.nvim plugin?: https://github.com/anuvyklack/hydra.nvim
-- NOTE: To get original behavior of `<C-w>` do it and simply wait for `timeoutlen`.
local function directional_split(direction)
  local saved_splitright = vim.o.splitright
  local saved_splitbelow = vim.o.splitbelow

  if direction == "up" then
    vim.o.splitbelow = false
    vim.cmd[[  split ]]
  elseif direction == "down" then
    vim.o.splitbelow = true
    vim.cmd[[  split ]]
  elseif direction == "left" then
    vim.o.splitright = false
    vim.cmd[[ vsplit ]]
  elseif direction == "right" then
    vim.o.splitright = true
    vim.cmd[[ vsplit ]]
  else
    vim.api.nvim_err_writeln(_f("Unknown split direction", _q(direction)))
  end

  vim.o.splitright = saved_splitright
  vim.o.splitbelow = saved_splitbelow
end
vim.keymap.set("n", "<C-w><C-h>", function() directional_split("left") end)
vim.keymap.set("n", "<C-w><C-j>", function() directional_split("down") end)
vim.keymap.set("n", "<C-w><C-k>", function() directional_split("up") end)
vim.keymap.set("n", "<C-w><C-l>", function() directional_split("right") end)
-- <wm-mappings>
global_leader_map{mode="n", key="<C-h>", desc="Split left", action=function() directional_split("left") end}
global_leader_map{mode="n", key="<C-j>", desc="Split down", action=function() directional_split("down") end}
global_leader_map{mode="n", key="<C-k>", desc="Split up", action=function() directional_split("up") end}
global_leader_map{mode="n", key="<C-l>", desc="Split right", action=function() directional_split("right") end}

-- Focus windows by WinNr
-- <C-w>N   -> N<C-w>w
--
-- mycfg-feature:direct-win-focus
do
  for i = 1, 9 do
    vim.keymap.set("n", "<C-w>"..i, i.."<C-w>w")
  end
end
-- TODO: 'jump-to-last' window
--   (keep history of ~10-15 windows to handle window deletions gracefully)

-- Smart window split (based on current window size)
local function smart_split()
  local win_width = vim.fn.winwidth(0)
  local win_height = vim.fn.winheight(0)
  if (win_width / 3) > win_height then
    directional_split("left")
  else
    directional_split("up")
  end
end
vim.keymap.set("n", "<C-w><C-s>", smart_split)

-- Full-width/height window splits
-- FIXME: Do I need this? Would I use this?
-- FIXME: Since I use noequalalways, the created splits takes way too much space...
--   => Maybe get current screen size and make the new one third of that?
--   I'd like to keep the ratios of existing windows
--   (don't almost completely hide a single window if there's space around!)
--   Instead of using <C-w>{H,J,K,L} to move the window,
--   I could create the window myself with commands like:
--     `botright 10split` to create a 10 lines full width window at the bottom
--nnoremap <C-M-w><C-M-h>   <cmd> split<cr><C-w>H
--nnoremap <C-M-w><C-M-j>   <cmd>vsplit<cr><C-w>J
--nnoremap <C-M-w><C-M-k>   <cmd>vsplit<cr><C-w>K
--nnoremap <C-M-w><C-M-l>   <cmd> split<cr><C-w>L

-- NOTE: Keys still available (not used often / ever)
-- * <C-w><C-HJKL>
-- * <C-w><C-M-hjkl>
--
-- TODO: window actions ideas:
-- -> Keys to move current buffer around in the visible (non-float, non-special) windows
-- -> (??) Keys to create a full-width/height BUT do not switch to it

--------------------------------

-- Start interactive EasyAlign in visual mode (e.g. vipgea)
--xmap gea <Plug>(EasyAlign)

-- Start interactive EasyAlign for a motion/text object (e.g. geaip)
--nmap gea <Plug>(EasyAlign)

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

-- Vim eval-and-replace:
-- Evaluate the current selection as a vimscript expression and replace
-- the selection with the result
-- NOTE1: changes the unnamed register
-- NOTE2: <C-r><C-r>{register} takes the register content verbatim
--   (whereas <C-r> inserts the register content as if typed)
--vnoremap <Plug>(my-EvalAndReplaceVimExpr-visual) c<C-r>=<C-r><C-r>"<cr><esc>
--
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
--
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


-- Search with{,out} word boundaries
-- V: search selection with word boundaries
--vmap * <Plug>(visualstar-*)
-- V: search selection without word boundaries
--vmap <M-*> <Plug>(visualstar-g*)
-- N: search current word without word boundaries
--nnoremap <M-*> g*

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

-- Save the file as sudo
--cnoremap w!! w !env SUDO_ASKPASS=$HOME/.bin-gui/zenity_passwd.sh sudo tee % >/dev/null


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

-- -- Edit
-- Use this to make a few nice mappings
-- Taken from: http://vimcasts.org/episodes/the-edit-command/
--lua <<LUA
--local_leader_map_define_group{mode={"n"}, prefix_key="e", name="+relative-edit"}
---- note: remap needed for '%/' to trigger!
--local_leader_remap{mode={"n"}, key="ee", action=":e %/",      desc="here"}
--local_leader_remap{mode={"n"}, key="es", action=":split %/",  desc="in split"}
--local_leader_remap{mode={"n"}, key="ev", action=":vsplit %/", desc="in v' split"}
--local_leader_remap{mode={"n"}, key="et", action=":tabe %/",   desc="in tab"}
--LUA

-- -----------------
-- IDEAS: (from vscode)
-- M-Up/Down -> Move current line (or range) up/down, following indentations
-- M-S-Up/Down -> Copy current line Up/Down
-- M-S-Left/Right -> Shrink/Expand (char-)selection (can be simulated in vim?
--     even without proper language support/detection?)
