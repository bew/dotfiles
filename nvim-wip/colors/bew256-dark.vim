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
  " BUT we want a compleately cleared group before setting our options so we
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
let s:base0       = "248"
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
let s:back        = "233"

let s:bg_base03_g  = ' ctermbg=22'
let s:bg_base03_r  = ' ctermbg=52'
let s:bg_base03_b  = ' ctermbg=24'

let s:fg_yellow_bright = ' ctermfg=11' " Same as 220?

let s:tab_current = s:base03   " dark_back
let s:tab_contrast = s:base3   " light_back
let s:tab_others = "239"

" Highlighting primitives"{{{
" ---------------------------------------------------------------------

exe "let s:bg_back      = ' ctermbg=".s:back   ."'"
exe "let s:bg_base03    = ' ctermbg=".s:base03 ."'"
exe "let s:bg_base02    = ' ctermbg=".s:base02 ."'"
exe "let s:bg_base01    = ' ctermbg=".s:base01 ."'"
exe "let s:bg_base00    = ' ctermbg=".s:base00 ."'"
exe "let s:bg_base0     = ' ctermbg=".s:base0  ."'"
exe "let s:bg_base1     = ' ctermbg=".s:base1  ."'"
exe "let s:bg_base2     = ' ctermbg=".s:base2  ."'"
exe "let s:bg_base3     = ' ctermbg=".s:base3  ."'"
exe "let s:bg_green     = ' ctermbg=".s:green  ."'"
exe "let s:bg_yellow    = ' ctermbg=".s:yellow ."'"
exe "let s:bg_orange    = ' ctermbg=".s:orange ."'"
exe "let s:bg_red       = ' ctermbg=".s:red    ."'"
exe "let s:bg_magenta   = ' ctermbg=".s:magenta."'"
exe "let s:bg_violet    = ' ctermbg=".s:violet ."'"
exe "let s:bg_blue      = ' ctermbg=".s:blue   ."'"
exe "let s:bg_cyan      = ' ctermbg=".s:cyan   ."'"

exe "let s:fg_base03    = ' ctermfg=".s:base03 ."'"
exe "let s:fg_base02    = ' ctermfg=".s:base02 ."'"
exe "let s:fg_base01    = ' ctermfg=".s:base01 ."'"
exe "let s:fg_base00    = ' ctermfg=".s:base00 ."'"
exe "let s:fg_base0     = ' ctermfg=".s:base0  ."'"
exe "let s:fg_base1     = ' ctermfg=".s:base1  ."'"
exe "let s:fg_base2     = ' ctermfg=".s:base2  ."'"
exe "let s:fg_base3     = ' ctermfg=".s:base3  ."'"
exe "let s:fg_green     = ' ctermfg=".s:green  ."'"
exe "let s:fg_yellow    = ' ctermfg=".s:yellow ."'"
exe "let s:fg_orange    = ' ctermfg=".s:orange ."'"
exe "let s:fg_red       = ' ctermfg=".s:red    ."'"
exe "let s:fg_magenta   = ' ctermfg=".s:magenta."'"
exe "let s:fg_violet    = ' ctermfg=".s:violet ."'"
exe "let s:fg_blue      = ' ctermfg=".s:blue   ."'"
exe "let s:fg_cyan      = ' ctermfg=".s:cyan   ."'"

exe "let s:fmt_bold     = ' cterm=bold'"
exe "let s:fmt_bldi     = ' cterm=bold'"
exe "let s:fmt_undr     = ' cterm=underline'"
exe "let s:fmt_undb     = ' cterm=underline,bold'"
exe "let s:fmt_curl     = ' cterm=none'"
exe "let s:fmt_ital     = ' cterm=italic'"

"}}}
" Basic highlighting"{{{
" ---------------------------------------------------------------------
" note that link syntax to avoid duplicate configuration doesn't work with the
" exe compiled formats

exe "HiResetTo Normal"   .s:fg_base0  .s:bg_back
" Darker background for non-current windows
exe "HiResetTo NormalNC ctermbg=232"

exe "HiResetTo Comment cterm=italic ctermfg=241"
"       *Comment         any comment

exe "HiResetTo Constant"   .s:fg_cyan
"       *Constant        any constant
"        String          a string constant: "this is a string"
"        Character       a character constant: 'c', '\n'
"        Number          a number constant: 234, 0xff
"        Boolean         a boolean constant: TRUE, false
"        Float           a floating point constant: 2.3e10

exe "HiResetTo Identifier"   .s:fg_blue
"       *Identifier      any variable name
"        Function        function name (also: methods for classes)
"
exe "HiResetTo Statement"   .s:fg_green
"       *Statement       any statement
"        Conditional     if, then, else, endif, switch, etc.
"        Repeat          for, do, while, etc.
"        Label           case, default, etc.
"        Operator        "sizeof", "+", "*", etc.
"        Keyword         any other keyword
"        Exception       try, catch, throw

exe "HiResetTo PreProc"   .s:fg_orange
"       *PreProc         generic Preprocessor
"        Include         preprocessor #include
"        Define          preprocessor #define
"        Macro           same as Define
"        PreCondit       preprocessor #if, #else, #endif, etc.

exe "HiResetTo Type"   .s:fg_yellow
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

exe "HiResetTo Todo"           .s:fmt_bold   .s:fg_yellow_bright
"       *Todo            anything that needs extra attention; mostly the
"                        keywords TODO FIXME and XXX
"
"}}}
" Extended highlighting "{{{
" ---------------------------------------------------------------------
exe "HiResetTo SpecialKey" .s:fmt_bold   .s:fg_base00 .s:bg_base02
exe "HiResetTo NonText ctermfg=237"
exe "HiResetTo StatusLine"   .s:fg_base02  .s:bg_base0
exe "HiResetTo StatusLineNC"   .s:fg_base02 .s:bg_base00
exe "HiResetTo Directory"   .s:fg_blue
exe "HiResetTo ErrorMsg"       .s:bg_red
exe "HiResetTo IncSearch"      .s:fmt_bold   .s:fg_base03 .s:bg_orange
exe "HiResetTo Search"         .s:fmt_bold   .s:fg_base03 .s:bg_yellow
exe "HiResetTo MoreMsg"   .s:fg_blue
exe "HiResetTo ModeMsg"   .s:fg_blue
exe "HiResetTo Question"       .s:fmt_bold   .s:fg_cyan
exe "HiResetTo VertSplit"  .s:fg_base02 .s:bg_base00

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

" Diff Colors
exe "HiResetTo DiffAdd"          .s:fmt_bold   .s:bg_base03_g
exe "HiResetTo DiffChange cterm=none"
HiResetTo DiffDelete ctermfg=240 ctermbg=52
exe "HiResetTo DiffText"         .s:fmt_bold   .s:bg_base03_b

" Signs
exe "HiResetTo SignColumn ctermbg=233"
exe "HiResetTo SignVcsAdd"      .s:fg_green
exe "HiResetTo SignVcsChange"   .s:fg_yellow
exe "HiResetTo SignVcsDelete"   .s:fg_red
exe "HiResetTo SignVcsUntracked".s:fg_cyan

exe "HiResetTo Conceal"   .s:fg_blue
exe "HiResetTo SpellBad"       .s:fmt_undr
exe "HiResetTo SpellCap"       .s:fmt_undr
exe "HiResetTo SpellRare"      .s:fmt_undr
exe "HiResetTo SpellLocal"     .s:fmt_undr
exe "HiResetTo Pmenu"   .s:fg_base02  .s:bg_base0
exe "HiResetTo PmenuSel"       .s:fmt_bold   .s:fg_base2 .s:bg_orange

" TODO: review the popup-menu' scrollbar highlight!
exe "HiResetTo PmenuSbar"   .s:fg_base0  .s:bg_base2
exe "HiResetTo PmenuThumb"   .s:fg_base03  .s:bg_base0

" Tab Colors
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

exe "HiResetTo MatchParen"     .s:fmt_bold   .s:fg_yellow_bright    .s:bg_base01

hi NormalFloat ctermfg=248 ctermbg=236

"}}}
" vim syntax highlighting "{{{
" ---------------------------------------------------------------------
"exe "HiResetTo vimLineComment" . s:fg_base01   .s:fmt_ital
"hi! link vimComment Comment
"hi! link vimLineComment Comment
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
exe "HiResetTo vimGroup"          .s:fmt_undb    .s:fg_blue
"}}}
" diff highlighting "{{{"{{{"}}}
" ---------------------------------------------------------------------
hi! link diffAdded DiffAdd
hi! link diffRemoved DiffDelete
hi! link diffLine Identifier
"}}}
" git & gitcommit highlighting "{{{
"git
"exe "HiResetTo gitDateHeader"
"exe "HiResetTo gitIdentityHeader"
"exe "HiResetTo gitIdentityKeyword"
"exe "HiResetTo gitNotesHeader"
"exe "HiResetTo gitReflogHeader"
"exe "HiResetTo gitKeyword"
"exe "HiResetTo gitIdentity"
"exe "HiResetTo gitEmailDelimiter"
"exe "HiResetTo gitEmail"
"exe "HiResetTo gitDate"
"exe "HiResetTo gitMode"
"exe "HiResetTo gitHashAbbrev"
"exe "HiResetTo gitHash"
"exe "HiResetTo gitReflogMiddle"
"exe "HiResetTo gitReference"
"exe "HiResetTo gitStage"
"exe "HiResetTo gitType"
"exe "HiResetTo gitDiffAdded"
"exe "HiResetTo gitDiffRemoved"
"gitcommit
"exe "HiResetTo gitcommitSummary"
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
"exe "HiResetTo gitcommitUnmergedType"
"exe "HiResetTo gitcommitType"
"exe "HiResetTo gitcommitNoChanges"
"exe "HiResetTo gitcommitHeader"
exe "HiResetTo gitcommitHeader"     .s:fg_base01
exe "HiResetTo gitcommitUntrackedFile".s:fmt_bold     .s:fg_cyan
exe "HiResetTo gitcommitDiscardedFile".s:fmt_bold     .s:fg_red
exe "HiResetTo gitcommitSelectedFile" .s:fmt_bold     .s:fg_green
exe "HiResetTo gitcommitUnmergedFile" .s:fmt_bold     .s:fg_yellow
exe "HiResetTo gitcommitFile"         .s:fmt_bold     .s:fg_base0
hi! link gitcommitDiscardedArrow gitcommitDiscardedFile
hi! link gitcommitSelectedArrow  gitcommitSelectedFile
hi! link gitcommitUnmergedArrow  gitcommitUnmergedFile
"exe "HiResetTo gitcommitArrow"
"exe "HiResetTo gitcommitOverflow"
"exe "HiResetTo gitcommitBlank"
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
" perl highlighting "{{{
" ---------------------------------------------------------------------
exe "HiResetTo perlHereDoc"    . s:fg_base1  .s:bg_back
exe "HiResetTo perlVarPlain"   . s:fg_yellow .s:bg_back
exe "HiResetTo perlStatementFileDesc". s:fg_cyan.s:bg_back

"}}}
" tex highlighting "{{{
" ---------------------------------------------------------------------
exe "HiResetTo texStatement"   . s:fg_cyan   .s:bg_back
exe "HiResetTo texMathZoneX"   . s:fg_yellow .s:bg_back
exe "HiResetTo texMathMatcher" . s:fg_yellow .s:bg_back
exe "HiResetTo texMathMatcher" . s:fg_yellow .s:bg_back
exe "HiResetTo texRefLabel"    . s:fg_yellow .s:bg_back
"}}}
" ruby highlighting "{{{
" ---------------------------------------------------------------------
exe "HiResetTo rubyDefine"     . s:fg_base1  .s:bg_back   .s:fmt_bold
"rubyInclude
"rubySharpBang
"rubyAccess
"rubyPredefinedVariable
"rubyBoolean
"rubyClassVariable
"rubyBeginEnd
"rubyRepeatModifier
"hi! link rubyArrayDelimiter    Special  " [ , , ]
"rubyCurlyBlock  { , , }

"hi! link rubyClass             Keyword
"hi! link rubyModule            Keyword
"hi! link rubyKeyword           Keyword
"hi! link rubyOperator          Operator
"hi! link rubyIdentifier        Identifier
"hi! link rubyInstanceVariable  Identifier
"hi! link rubyGlobalVariable    Identifier
"hi! link rubyClassVariable     Identifier
"hi! link rubyConstant          Type
"}}}
" haskell syntax highlighting"{{{
" ---------------------------------------------------------------------
" For use with syntax/haskell.vim : Haskell Syntax File
" http://www.vim.org/scripts/script.php?script_id=3034
" See also Steffen Siering's github repository:
" http://github.com/urso/dotrc/blob/master/vim/syntax/haskell.vim
" ---------------------------------------------------------------------
"
" Treat True and False specially, see the plugin referenced above
let hs_highlight_boolean=1
" highlight delims, see the plugin referenced above
let hs_highlight_delimiters=1

exe "HiResetTo cPreCondit". s:fg_orange

exe "HiResetTo VarId"    . s:fg_blue
exe "HiResetTo ConId"    . s:fg_yellow
exe "HiResetTo hsImport" . s:fg_magenta
exe "HiResetTo hsString" . s:fg_base00

exe "HiResetTo hsStructure"        . s:fg_cyan
exe "HiResetTo hs_hlFunctionName"  . s:fg_blue
exe "HiResetTo hsStatement"        . s:fg_cyan
exe "HiResetTo hsImportLabel"      . s:fg_cyan
exe "HiResetTo hs_OpFunctionName"  . s:fg_yellow
exe "HiResetTo hs_DeclareFunction" . s:fg_orange
exe "HiResetTo hsVarSym"           . s:fg_cyan
exe "HiResetTo hsType"             . s:fg_yellow
exe "HiResetTo hsTypedef"          . s:fg_cyan
exe "HiResetTo hsModuleName"       . s:fg_green   .s:fmt_undr
exe "HiResetTo hsModuleStartLabel" . s:fg_magenta
hi! link hsImportParams      Delimiter
hi! link hsDelimTypeExport   Delimiter
hi! link hsModuleStartLabel  hsStructure
hi! link hsModuleWhereLabel  hsModuleStartLabel

" following is for the haskell-conceal plugin
" the first two items don't have an impact, but better safe
exe "HiResetTo hsNiceOperator"     . s:fg_cyan
exe "HiResetTo hsniceoperator"     . s:fg_cyan

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
