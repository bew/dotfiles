" =============================================================================
" Inspired from https://github.com/itchyny/lightline.vim/blob/master/autoload/lightline/colorscheme/jellybeans.vim
" =============================================================================

" Example colors (preview them with plugin Colorizer)
" ctermbg=233
" ctermbg=235
" ctermbg=236
" ctermbg=240
" ctermbg=242
" ctermbg=244
" ctermbg=246
" ctermbg=248
" ctermbg=220
" ctermbg=208
" ctermbg=88
" ctermbg=97
" ctermbg=27
" ctermbg=28
" ctermbg=255

let s:bg_default = ['', 236]
let s:fg_default = ['', 244]
let s:bg_default_inactive = s:bg_default
let s:fg_default_inactive = ['', 241]

let s:base03 = ['', 235]
let s:base02 = ['', 236]
let s:base01 = ['', 240]
let s:base00 = ['', 242]
let s:base0 = ['', 244]
let s:base1 = ['', 246]
let s:base2 = ['', 248]
let s:deep_dark = ['', 234]
let s:yellow = ['', 220]
let s:orange = ['', 208]
let s:red = ['', 88]
let s:mauve = ['', 97]
let s:blue = ['', 27]
let s:green = ['', 28]
let s:white = ['', 255]
let s:less_white = ['', 253]

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

let s:active_sgmt2 = [ s:less_white, s:base01 ]
let s:p['normal'].left = [ [ s:white, s:blue, 'bold' ], s:active_sgmt2 ]
let s:p.insert.left = [ [ s:white, s:green, 'bold' ], s:active_sgmt2 ]
let s:p.replace.left = [ [ s:white, s:red, 'bold' ], s:active_sgmt2 ]
let s:p.visual.left = [ [ s:white, s:mauve, 'bold' ], s:active_sgmt2 ]

let s:p['normal'].right = [ [ s:base02, s:base1 ], [ s:base2, s:base01 ] ]
let s:p['normal'].middle = [ [ s:fg_default, s:bg_default ] ]
let s:p['normal'].error = [ [ s:red, s:bg_default ] ]
let s:p['normal'].warning = [ [ s:yellow, s:bg_default ] ]

let s:p.inactive.left =  [ [ s:fg_default_inactive, s:base03 ], [ ['', 246], ['', 238] ] ]
let s:p.inactive.right = [ [ s:deep_dark, s:base01 ], [ s:fg_default_inactive, s:bg_default_inactive ] ]
let s:p.inactive.middle = [ [ s:fg_default_inactive, s:bg_default_inactive ] ]

let s:p.tabline.left = copy(s:p.normal.middle)
let s:p.tabline.tabsel = [ [ s:white, s:base00 ] ]
let s:p.tabline.middle = copy(s:p.normal.middle)
let s:p.tabline.right = copy(s:p.tabline.middle)

let g:lightline#colorscheme#bew#palette = lightline#colorscheme#flatten(s:p)
