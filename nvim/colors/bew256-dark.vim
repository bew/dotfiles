" Name:     bew256-dark vim colorscheme

" Environment Specific Overrides "{{{
" Allow or disallow certain features based on current terminal emulator or 
" environment.

" }}}
" Colorscheme initialization "{{{
" ---------------------------------------------------------------------
hi clear
if exists("syntax_on")
  syntax reset
endif
let colors_name = "bew256-dark"

"}}}

" Highlight micro DSL definition "{{{
function! s:reset_highlight(group, ...)
  " Reset the highlighting of *group* to <...>

  " When using hi! or hi clear of syntax clear, the syntax groups uses the
  " nvim's default, and non-specified cterm* option will be nvim's default.
  " BUT we want a completely cleared group before setting our options so we
  " first clear everything and 'paste' our options afterward.
  let hi_reset = " cterm=none ctermfg=none ctermbg=none "
  exe "hi! " . a:group . l:hi_reset . join(a:000, " ")
endf

" Usage: HiResetTo SomeHiGroup ctermfg=foo
" Will set cterm/ctermfg/ctermbg to none and then set ctermfg to foo
command! -nargs=+ HiResetTo call s:reset_highlight(<f-args>)
"}}}

let s:base03      = "233"
let s:base02      = "234"
let s:base01      = "239"
let s:base00      = "240"
let s:base0       = "249"
let s:base1       = "111"
let s:base2       = "187"
let s:base3       = "230"
let s:yellow      = "136"
let s:orange      = "166"
let s:red         = "124"
let s:magenta     = "125"
let s:violet      = "99"
let s:blue        = "33"
let s:cyan        = "37"
let s:green       = "70"

let s:fg_bright_yellow = ' ctermfg=11' " Same as 220?

" Highlighting primitives"{{{
" ---------------------------------------------------------------------

exe "let s:bg_base02    = ' ctermbg=".s:base02 ."'"
exe "let s:bg_base01    = ' ctermbg=".s:base01 ."'"
exe "let s:bg_base00    = ' ctermbg=".s:base00 ."'"
exe "let s:bg_base0     = ' ctermbg=".s:base0  ."'"
exe "let s:bg_base2     = ' ctermbg=".s:base2  ."'"

exe "let s:fg_base03    = ' ctermfg=".s:base03 ."'"
exe "let s:fg_base02    = ' ctermfg=".s:base02 ."'"
exe "let s:fg_base01    = ' ctermfg=".s:base01 ."'"
exe "let s:fg_base00    = ' ctermfg=".s:base00 ."'"
exe "let s:fg_base0     = ' ctermfg=".s:base0  ."'"
exe "let s:fg_base1     = ' ctermfg=".s:base1  ."'"
exe "let s:fg_green     = ' ctermfg=".s:green  ."'"
exe "let s:fg_yellow    = ' ctermfg=".s:yellow ."'"
exe "let s:fg_orange    = ' ctermfg=".s:orange ."'"
exe "let s:fg_red       = ' ctermfg=".s:red    ."'"
exe "let s:fg_magenta   = ' ctermfg=".s:magenta."'"
exe "let s:fg_violet    = ' ctermfg=".s:violet ."'"
exe "let s:fg_blue      = ' ctermfg=".s:blue   ."'"
exe "let s:fg_cyan      = ' ctermfg=".s:cyan   ."'"

exe "let s:fmt_bold     = ' cterm=bold'"
exe "let s:fmt_undr     = ' cterm=underline'"
exe "let s:fmt_ital     = ' cterm=italic'"

"}}}
" Basic highlighting"{{{
" ---------------------------------------------------------------------
" note that link syntax to avoid duplicate configuration doesn't work with the
" exe compiled formats

exe "HiResetTo Normal"   .s:fg_base0  .' ctermbg=233'
" Darker background for non-current windows
exe "HiResetTo NormalNC ctermbg=232"

HiResetTo Comment cterm=italic ctermfg=241
"       *Comment         any comment

exe "HiResetTo Constant"   .s:fg_cyan
"       *Constant        any constant
"        String          a string constant: "this is a string"
"        Character       a character constant: 'c', '\n'
"        Number          a number constant: 234, 0xff
"        Boolean         a boolean constant: TRUE, false
"        Float           a floating point constant: 2.3e10
hi! link String Constant

exe "HiResetTo Identifier"   .s:fg_blue
"       *Identifier      any variable name
"        Function        function name (also: methods for classes)
hi! link Function Identifier
"
exe "HiResetTo Statement"   .s:fg_green
"       *Statement       any statement
"        Conditional     if, then, else, endif, switch, etc.
"        Repeat          for, do, while, etc.
"        Label           case, default, etc.
"        Keyword         any other keyword
"        Exception       try, catch, throw
HiResetTo Operator cterm=bold ctermfg=215

exe "HiResetTo PreProc"   .s:fg_orange
"       *PreProc         generic Preprocessor
"        Include         preprocessor #include
"        Define          preprocessor #define
"        Macro           same as Define
"        PreCondit       preprocessor #if, #else, #endif, etc.

hi! link Type @type
"       *Type            int, long, char, etc.
"        StorageClass    static, register, volatile, etc.
"        Structure       struct, union, enum, etc.
"        Typedef         A typedef

exe "HiResetTo Special"   .s:fg_red
"       *Special         any special symbol
"        SpecialChar     special character in a constant
"        Tag             you can use CTRL-] on this
"        Delimiter       character that needs attention
"        SpecialComment  special things inside a comment
"        Debug           debugging statements

exe "HiResetTo Underlined"   .s:fg_violet
"       *Underlined      text that stands out, HTML links

exe "HiResetTo Ignore cterm=none"
"       *Ignore          left blank, hidden  |hl-Ignore|

exe "HiResetTo Error"          .s:fmt_bold   .s:fg_red
"       *Error           any erroneous construct

exe "HiResetTo Todo"           .s:fmt_bold   .s:fg_bright_yellow
"       *Todo            anything that needs extra attention; mostly the
"                        keywords TODO FIXME and XXX
"
"}}}
" Extended highlighting "{{{
" ---------------------------------------------------------------------
exe "HiResetTo SpecialKey" .s:fmt_bold   .s:fg_base00 .s:bg_base02
exe "HiResetTo NonText ctermfg=237"
exe "HiResetTo StatusLine"   .s:fg_base02  .s:bg_base0
HiResetTo QuickFixLine cterm=bold ctermbg=236
exe "HiResetTo StatusLineNC"   .s:fg_base02 .s:bg_base00
exe "HiResetTo Directory"   .s:fg_blue
HiResetTo ErrorMsg ctermbg=124 ctermfg=255 cterm=bold
exe "HiResetTo MoreMsg"   .s:fg_blue
exe "HiResetTo ModeMsg"   .s:fg_blue
exe "HiResetTo Question"       .s:fmt_bold   .s:fg_cyan
exe "HiResetTo VertSplit"  .s:fg_base02 .s:bg_base00
hi! link WinSeparator VertSplit

HiResetTo IncSearch      cterm=bold ctermfg=233 ctermbg=166
HiResetTo Search         cterm=bold ctermfg=233 ctermbg=136
hi! link CurSearch IncSearch

" 236 (grey)
" 17 (dark blue) is nice BUT a bit too subtle
" 52 (dark red) is VERY visible (too much? needs to have a toggle)
exe "HiResetTo VisualNormal ctermbg=236 cterm=bold"
exe "HiResetTo VisualHighContrast ctermbg=52"
" ^^^ HighContrast variant can be helpful when sharing screen, to better show what I have selected
" NOTE: Would be nice to have a visual binding to toggle between the 2 :)
hi! link Visual VisualNormal
hi! link VisualNOS Visual

exe "HiResetTo Title"          .s:fmt_bold   .s:fg_orange
exe "HiResetTo WarningMsg"     .s:fmt_bold   .s:fg_red
exe "HiResetTo WildMenu"   .s:fg_base02  .s:bg_base2
exe "HiResetTo Folded"   .s:fg_base0  ." ctermbg=236"
HiResetTo FoldColumn ctermfg=240 ctermbg=233

HiResetTo SignColumn ctermbg=233

" Diff & VCS
HiResetTo DiffAdd    cterm=bold ctermbg=22
HiResetTo DiffChange cterm=none
HiResetTo DiffDelete ctermfg=240 ctermbg=52
HiResetTo DiffText   cterm=bold ctermbg=24

" VCS Untracked
HiResetTo VcsUntracked cterm=bold ctermfg=37
" VCS unstaged
HiResetTo VcsAdd       ctermfg=70
HiResetTo VcsChange    ctermfg=208
HiResetTo VcsDelete    ctermfg=160
" VCS staged (darker)
HiResetTo VcsStagedAdd    ctermfg=28
HiResetTo VcsStagedChange ctermfg=94
HiResetTo VcsStagedDelete ctermfg=53
" ctermfg=88 is too bright, ctermfg=52 is too dark.. pick something else..

exe "HiResetTo Conceal"   .s:fg_blue
HiResetTo SpellBad     cterm=underline
HiResetTo SpellCap     cterm=underline
HiResetTo SpellRare    cterm=underline
HiResetTo SpellLocal   cterm=underline

" builtin popup-menu:
HiResetTo Pmenu                 ctermfg=234 ctermbg=249
HiResetTo PmenuSel  cterm=bold  ctermfg=187 ctermbg=166
" builtin popup-menu scrollbar:
HiResetTo PmenuSbar   ctermfg=249  ctermbg=187
HiResetTo PmenuThumb  ctermfg=233  ctermbg=249

" Tab Colors
let s:tab_current = s:base03   " dark_back
let s:tab_contrast = s:base3   " light_back
let s:tab_others = "239"
exe "HiResetTo TabLineSel  cterm=bold  ctermfg=".s:tab_contrast ." ctermbg=".s:tab_current
exe "HiResetTo TabLine     ctermfg=".s:tab_contrast ." ctermbg=".s:tab_others

exec "HiResetTo TabLineFill ctermbg=".s:tab_contrast

" Wanted with DynHi for tab line hi config:
" DynHi TabLineFill bg=XYZ
" DynHi TabLineSel  fg=TabLineFill.bg  bg=Normal.bg  style=bold
" DynHi TabLine     fg=TabLineFill.bg  bg=Normal.bg+50%

exe "HiResetTo CursorColumn"   .s:bg_base02
exe "HiResetTo CursorLine"   .s:bg_base02

exe "HiResetTo LineNr"   .s:fg_base01 .s:bg_base02
exe "HiResetTo CursorLineNr"   .s:fg_cyan   ." ctermbg=237 cterm=bold"
hi! link ColorColumn CursorColumn
exe "HiResetTo Cursor"   .s:fg_base03 .s:bg_base0

exe "HiResetTo MatchParen"     .s:fmt_bold   .s:fg_bright_yellow    .s:bg_base01

hi NormalFloat ctermfg=248 ctermbg=235

"}}}
" Diagnostic highlighting "{{{
" ---------------------------------------------------------------------
" Disable 'unnecessary' group, that completely dims the code by default and hides all colors
" (makes code hard to work with when it is marked unused by LSPs!)
HiResetTo DiagnosticUnnecessary

HiResetTo DiagnosticDeprecated cterm=strikethrough,underline guisp=#fad43d

HiResetTo DiagnosticInfo ctermfg=14
HiResetTo DiagnosticUnderlineInfo cterm=underline gui=underline guisp=#75ace2

HiResetTo DiagnosticHint ctermfg=12
HiResetTo DiagnosticUnderlineHint cterm=underline gui=underline guisp=#89b6e2

HiResetTo DiagnosticWarn ctermfg=11
HiResetTo DiagnosticUnderlineWarn cterm=underline gui=underline guisp=#fad43d

HiResetTo DiagnosticError ctermfg=9
HiResetTo DiagnosticUnderlineError cterm=underline gui=underline guisp=#ff6565

"}}}
" Tree-sitter highlighting "{{{
" ---------------------------------------------------------------------
HiResetTo @type ctermfg=214
HiResetTo @type.builtin ctermfg=131

HiResetTo @keyword ctermfg=70
HiResetTo @keyword.exception ctermfg=160 cterm=bold

HiResetTo @function ctermfg=33
HiResetTo @function.call ctermfg=208
HiResetTo @function.method.call ctermfg=208
HiResetTo @function.macro ctermfg=208
HiResetTo @function.builtin ctermfg=166 cterm=bold,italic
HiResetTo @constructor ctermfg=166 cterm=bold

" `@variable` fg = `Normal` fg
" This is necessary to take precedence in string interpolations
HiResetTo @variable ctermfg=249
HiResetTo @variable.member ctermfg=39
HiResetTo @variable.builtin ctermfg=253 cterm=italic
HiResetTo @variable.parameter cterm=italic
" e.g. for python: `foo` in `hello(foo=...)`
" e.g. for bash: `-o` / `--option`
HiResetTo @variable.parameter.argument ctermfg=137

HiResetTo @string ctermfg=37
HiResetTo @string.regexp ctermfg=36

HiResetTo @comment.documentation ctermfg=243 cterm=nocombine
" This is used for strings that are considered as docs, like Python docstrings
hi! link @string.documentation @comment.documentation

" note: _emphasis_ certain documentation sections
" (used _at least_ in python docstrings thx to my hl_patterns)
HiResetTo @comment.documentation.emph ctermfg=246
HiResetTo @comment.documentation.emph.return ctermfg=28
HiResetTo @comment.documentation.emph.exception ctermfg=124

" The key in a key/value pairs
HiResetTo @property ctermfg=137

HiResetTo @tag ctermfg=33 cterm=bold
HiResetTo @tag.delimiter ctermfg=25
hi! link @tag.attribute @property

" /!\ This is used for most delimiters in various languages (Lua, ...)
" Make sure it stays properly visible!
HiResetTo @punctuation.delimiter ctermfg=244

hi! link @markup.quote Comment
HiResetTo @markup.raw ctermfg=29 ctermbg=234
HiResetTo @markup.raw.block ctermfg=29
" note: No bg for block, to avoid bg leaking in indent when raw block is indented

" Give a progression/difference between H1, H2, H3.. headings
" NOTE: hl groups (not `..bg`) are shared between markdown & :help files (at least).
" -- H1
HiResetTo @markup.heading.1    ctermfg=50 cterm=bold
HiResetTo @markup.heading.1.bg ctermbg=237
" -- H2
HiResetTo @markup.heading.2    ctermfg=39  cterm=bold
HiResetTo @markup.heading.2.bg ctermbg=236
" -- H3
HiResetTo @markup.heading.3    ctermfg=208 cterm=bold
HiResetTo @markup.heading.3.bg ctermbg=235
" -- H4
HiResetTo @markup.heading.4    ctermfg=64  cterm=bold
HiResetTo @markup.heading.4.bg ctermbg=234
" -- H5
HiResetTo @markup.heading.5    ctermfg=126 cterm=bold
HiResetTo @markup.heading.5.bg ctermbg=234
" -- H6
HiResetTo @markup.heading.6    ctermfg=91  cterm=bold
HiResetTo @markup.heading.6.bg ctermbg=234

" This is used by some languages queries to cancel surrounding highlighting
" (e.g. python's f-string interpolations)
hi! link @none Normal

"}}}
" Tree-sitter highlighting (Language-specific overrides) "{{{

" [Markdown]
HiResetTo @punctuation.delimiter.markdown ctermfg=239
HiResetTo @markup.raw.delimiter.markdown ctermfg=239

" [Markdown (inline)]
HiResetTo @punctuation.delimiter.markdown_inline ctermfg=239
HiResetTo @markup.italic.markdown_inline cterm=italic ctermfg=255 ctermbg=235
HiResetTo @markup.strong.markdown_inline cterm=bold ctermfg=255 ctermbg=235

" [Bash]
" Ensure variable / constant / special vars do stand out from strings
HiResetTo @variable.bash       ctermfg=39
HiResetTo @variable.short.bash ctermfg=39 cterm=bold
HiResetTo @variable.special.bash ctermfg=222
HiResetTo @constant.bash ctermfg=171

" [Rust]
" Show `super`/`self` in dedicated color (not keyword or path item)
HiResetTo @module.builtin.rust cterm=italic ctermfg=180
" Same but at crate-level (larger scope)
HiResetTo @module.builtin.crate.rust cterm=italic,underdotted ctermfg=180
" TODO
HiResetTo @keyword.public cterm=bold ctermfg=70

"}}}
" LSP highlighting "{{{
" ---------------------------------------------------------------------
" NOTE: By default @lsp.* hl groups link to treesitter groups
" HiResetTo @lsp.mod.deprecated
" HiResetTo @lsp.type.class
" HiResetTo @lsp.type.comment
" HiResetTo @lsp.type.decorator
" HiResetTo @lsp.type.enum
" HiResetTo @lsp.type.enumMember
" HiResetTo @lsp.type.event
" HiResetTo @lsp.type.function
" HiResetTo @lsp.type.interface
" HiResetTo @lsp.type.keyword
" HiResetTo @lsp.type.macro
" HiResetTo @lsp.type.method
" HiResetTo @lsp.type.modifier
" HiResetTo @lsp.type.namespace
" HiResetTo @lsp.type.number
" HiResetTo @lsp.type.operator
" HiResetTo @lsp.type.parameter
" HiResetTo @lsp.type.property
" HiResetTo @lsp.type.regexp
" HiResetTo @lsp.type.string
" HiResetTo @lsp.type.struct
" HiResetTo @lsp.type.type
" HiResetTo @lsp.type.typeParameter
" HiResetTo @lsp.type.variable
"}}}
" LSP highlighting (Language-specific overrides) "{{{
" ---------------------------------------------------------------------

" [Lua]
" Disable forced LSP comments, as they overwrite @comment.documentation
HiResetTo @lsp.type.comment.lua

" [Terraform]
" Disable forced LSP strings, as they hide any language injections in heredoc multiline strings
HiResetTo @lsp.type.string.terraform

" [Rust]
" Disable forced function call the same as function def 😬
HiResetTo @lsp.type.function.rust
HiResetTo @lsp.type.method.rust
" Ensure properties are highlighted as members
hi! link @lsp.type.property.rust @variable.member.rust
" Disable forced non-obvious keywords
HiResetTo @lsp.type.keyword.rust
" Highlight fmt format modifiers like `{:?}` in `println!("{foo:?}");`
HiResetTo @lsp.type.formatSpecifier.rust ctermfg=124

"}}}
" vim syntax highlighting "{{{
" ---------------------------------------------------------------------
hi! link vimVar Identifier
hi! link vimFunc Function
hi! link vimUserFunc Function
hi! link helpSpecial Special
hi! link vimSet Normal
hi! link vimSetEqual Normal
exe "HiResetTo vimCommentString"    .s:fg_violet
exe "HiResetTo vimCommand"    .s:fg_yellow
exe "HiResetTo vimCmdSep"         .s:fmt_bold    .s:fg_blue
exe "HiResetTo helpExample"    .s:fg_base1
exe "HiResetTo helpOption"    .s:fg_cyan
exe "HiResetTo helpNote"    .s:fg_magenta
exe "HiResetTo helpVim"    .s:fg_magenta
exe "HiResetTo helpHyperTextJump" .s:fmt_undr    .s:fg_blue
exe "HiResetTo helpHyperTextEntry"    .s:fg_green
exe "HiResetTo vimIsCommand ctermfg=28"
exe "HiResetTo vimSynMtchOpt"    .s:fg_yellow
exe "HiResetTo vimSynType"    .s:fg_cyan
exe "HiResetTo vimHiLink"    .s:fg_blue
exe "HiResetTo vimHiGroup"    .s:fg_blue
exe "HiResetTo vimGroup  cterm=underline,bold"    .s:fg_blue
"}}}
" git & gitcommit highlighting "{{{
"gitcommit
exe "HiResetTo gitcommitComment"      .s:fmt_ital     .s:fg_base01
hi! link gitcommitUntracked gitcommitComment
hi! link gitcommitDiscarded gitcommitComment
hi! link gitcommitSelected  gitcommitComment
exe "HiResetTo gitcommitUnmerged"     .s:fmt_bold     .s:fg_green
exe "HiResetTo gitcommitOnBranch"     .s:fmt_bold     .s:fg_base01
exe "HiResetTo gitcommitBranch"       .s:fmt_bold     .s:fg_magenta
hi! link gitcommitNoBranch gitcommitBranch
exe "HiResetTo gitcommitDiscardedType"     .s:fg_red
exe "HiResetTo gitcommitSelectedType"     .s:fg_green
exe "HiResetTo gitcommitHeader"     .s:fg_base01
exe "HiResetTo gitcommitUntrackedFile".s:fmt_bold     .s:fg_cyan
exe "HiResetTo gitcommitDiscardedFile".s:fmt_bold     .s:fg_red
exe "HiResetTo gitcommitSelectedFile" .s:fmt_bold     .s:fg_green
exe "HiResetTo gitcommitUnmergedFile" .s:fmt_bold     .s:fg_yellow
exe "HiResetTo gitcommitFile"         .s:fmt_bold     .s:fg_base0
hi! link gitcommitDiscardedArrow gitcommitDiscardedFile
hi! link gitcommitSelectedArrow  gitcommitSelectedFile
hi! link gitcommitUnmergedArrow  gitcommitUnmergedFile
" }}}
" html highlighting "{{{
" ---------------------------------------------------------------------
exe "HiResetTo htmlTag" .s:fg_base01
exe "HiResetTo htmlEndTag" .s:fg_base01
exe "HiResetTo htmlTagN"          .s:fmt_bold .s:fg_base1
exe "HiResetTo htmlTagName"       .s:fmt_bold .s:fg_blue
exe "HiResetTo htmlSpecialTagName".s:fmt_ital .s:fg_blue
exe "HiResetTo htmlArg" .s:fg_base00
exe "HiResetTo javaScript" .s:fg_yellow
"}}}
" License "{{{
" ---------------------------------------------------------------------
"
" Copyright (c) 2011 Ethan Schoonover
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.
"
" vim:foldmethod=marker:foldlevel=0
"}}}
