-- Options
-- --------------------------------------------------------------------

-- TODO: keep around (somewhere / commented / at the bottom?) the options that
-- could be useful in vim but are default in nvim..

-- NOTE: to review later, when filetype.lua is default, what's important to keep
vim.cmd[[filetype plugin indent on]]

-- allow backspacing over everything in insert mode
--set backspace=indent,eol,start
-- NOTE: default in nvim

-- Let's try! It's usually nice to have, and I don't often need identifiers without - if any..
-- NOTE(side effect): word movements now move above dashes
--   => I have to move/select with `t-` if I don't want this..
vim.opt.iskeyword:append("-")

-- always show the statusline
vim.o.laststatus = 2

--set history=99      -- keep 99 lines of command line history
-- NOTE: now default is HUGE

--set ruler     -- show the cursor position all the time
-- NOTE: default in nvim

--set showcmd     -- display incomplete commands
-- NOTE: default in nvim

-- disable -- INSERT --
-- I already have the info with cursor shape and in statusline
vim.o.showmode = false

-- set hlsearch      -- do highlight the searched text
-- This is the default, and it re-hl the last search when reloading nvim's config, so let's keep it but commented
-- NOTE: default in nvim, remove?

--set incsearch     -- incremental search as you type
-- NOTE: default in nvim

vim.o.inccommand = "split"   -- incremental preview of substitution command (NOTE: :s only, not plugin's :S)

-- apply smart case searching
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.number = true
vim.o.relativenumber = true

-- Draw signcolumn only if needed and resize for up to N signs on same line
vim.o.signcolumn = "auto:2"

-- highlight the line/col of the cursor
vim.o.cursorline = true
-- set cursorcolumn    -- disabled for now, as it removes the nice ligatures above/below cursor

vim.o.equalalways = false   -- Avoid windows auto-resizing on win opened/closed

vim.o.mouse = "nv"   -- Enable mouse in normal & visual
-- Disable new popup menu on left click, always extend visual selection!
vim.o.mousemodel = "extend"

-- Change the way text is displayed
vim.opt.display = {
  "lastline", -- Show last line of window as much as possible
  "truncate", -- 'lastline' + shows when last line isn't fully rendered
  "msgsep", -- When showing more than 'cmdheight' lines of msg, only scroll the message lines, not the entire screen.
}

vim.o.showbreak = "……"   -- Prefix for wrapped lines
vim.o.linebreak = true      -- Wrapping will break lines on word boundaries

--set hidden   -- Allow to have unsaved hidden buffers
-- NOTE: default in nvim

--set timeoutlen=1000
-- NOTE: default in nvim

vim.o.updatetime = 500    -- Time (ms) before swapfile & CursorHold autocmd triggers

-- Auto indent the next line
--set autoindent
-- NOTE: default in nvim

-- Round indent to multiple of 'shiftwidth'
-- (sw=4, indent=2, '>>' puts indent to 4 not 6)
vim.o.shiftround = true

-- Completion popup
vim.o.pumheight = 20

vim.o.foldmethod = "manual"     -- the default, but make it explicit
vim.o.foldcolumn = "auto:2"     -- Auto show fold column, use at most 2 columns

-- Show non visible chars (tabs/trailing spaces/too long lines/etc..)
vim.o.list = true
vim.opt.listchars = {
  tab = "· ",      -- Tab char
  trail = "@",     -- Trailing spaces
  precedes = "<",  -- First char when line too long for display
  extends = ">",   -- Last char when line too long for display
}

-- Set the char to use to fill some blanks
vim.opt.fillchars = {
  fold = "╶",     -- right side of a closed fold (default: '·')
  diff = "╱",   -- (fully diagonal line) - deleted lines of the 'diff' option (default: '-')
  eob = " ",     -- empty lines at the end of a buffer (default: '~')
  vert = " ",    -- separator between vertical splits
}

vim.o.scrolloff = 3           -- minimum lines to keep above and below cursor
vim.o.sidescrolloff = 16        -- minimum chars to keep on the left/right of the cursor

--set sidescroll=1          -- side scroll chars one by one
-- NOTE: default in nvim

-- Command line options
--set wildmenu            -- show list instead of just completing
-- NOTE: default in nvim
vim.o.wildmode = "longest:full,full"    -- commandline <Tab> completion, list matches, then longest common part, then all.
vim.o.wildignorecase = true      -- ignore case when completing filenames

-- Use 'best' algo, works best for english words, also finds chnges for algo 'fast' (typing mistzkes)
-- Show at most N suggegstions (instead of a whole page)
vim.o.spellsuggest = "best,10"

-- setup default fold
--set nofoldenable   -- leave fold open on file open

----- Format options

-- Disable auto wrap comment automatically
vim.opt.formatoptions:remove("t")   -- for text
vim.opt.formatoptions:remove("c")   -- for comments

-- Disable auto-format of paragraphs
vim.opt.formatoptions:remove("a")

-- Enable auto comment new line when pressing <Enter> in insert mode
vim.opt.formatoptions:append("r")

-- Enable correct comment join (remove comment start)
vim.opt.formatoptions:append("j")
-----

-- Set prefered text width, used for as-you-type auto-formating and manual formating with gq
vim.o.textwidth = 100

-- Do not insert 2 spaces after a '.', '?' and '!' with a join command. Use a single space.
--set nojoinspaces
-- NOTE: default in nvim

-- Use a completion menu, always show the menu (even if only one match)
vim.o.completeopt = "menu,menuone"

----- cmdline search ignore
-- obj files
vim.opt.wildignore:append("*.o")
-- java/scala build files
vim.opt.wildignore:append({
  "*.jar",
  "*.class",
  "project/target/*",
  "target/scala*",
  "target/streams*",
})
-- TODO: to update! (?)

-- Default indentation
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true   -- Always expand TAB to spaces

-- vim's continuation line indent defaults to 3 * shiftwidth, it's
-- too much, let's reduce it:
vim.g.vim_indent_cont = 4


-- Setting colorscheme
--syntax enable   -- Not 'syntax on' which overrides colorscheme
-- NOTE: default in nvim

-- Setup swap/undo files
vim.o.undofile = true
vim.o.swapfile = true
-- Options 'directory' & 'undodir' ends with '//' so that the swap/undo file
-- name will be built from the absolute path to the file with all path separators
-- substituted to percent '%' signs.
-- This will ensure file name uniqueness in the directory.
vim.o.undodir = vim.fn.stdpath("state") .. "/undofiles//"
vim.o.directory = vim.fn.stdpath("state") .. "/swapfiles//"
