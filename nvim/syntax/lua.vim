

" match 'myfunc()' and 'myfunc   ()'
syn match luaUserFunc "\<[a-zA-Z_][a-zA-Z0-9_]*\>\ze\s\{-}("

syn keyword luaKeyword self contained

" match 'mytable.' and 'mytable:'
syn match luaTableReference /\<\w\+\>\(\.\|:\)/

" match 'MyClass' but not 'MYClass' or 'myClass'
syn match luaClass "\<\u\l\w\{-}\>"

" match 'word space =' contained in 'luaTable'
" TODO !! (doesn't work :(  )
"syn match luaTableField "\<\w\{-1,}\>\ze\s\{-}=" containedin=luaTable containedin=ALLBUT,luaFunctionBlock contained





" We should move this in appropriate file ?

hi link luaKeyword Statement

hi luaTable cterm=bold ctermfg=2
hi luaClass cterm=NONE ctermfg=2

hi link luaUserFunc luaFunc


hi luaTableField cterm=reverse ctermfg=162
