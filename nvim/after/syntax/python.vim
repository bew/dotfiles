" Remove any of these if already defined
silent! syntax clear pythonFunctionCall
silent! syntax clear pythonFunctionCallKwargs
silent! syntax clear pythonType
silent! syntax clear pythonSelf
silent! syntax clear pythonBuiltinType

syn case match " respect case

" Match a function call: 'foobar' in 'foobar(args)'
syn match pythonFunctionCall /\<_*\l\w*\ze(/
hi def pythonFunctionCall ctermfg=209

" Match named arguments: 'arg=' in 'func_call(arg=1)'
syn match pythonFunctionCallKwargs /\<_*\l\w*=/
hi def pythonFunctionCallKwargs ctermfg=137

" Match a type (identifier that starts with an uppercase), like 'FooBar'
" Does not match if the type is after a dot (see below)
syn match pythonType /[^.]\zs\<_*\u\w*\>/
" If the type is after a dot, the word before the dot must not be a type:
"   low.Image            # 'low' is a module name -> 'Image' is a type
"   ImageStatus.CREATED  # 'ImageStatus' is a type -> 'CREATED' cannot be a type (it's an enum value)
syn match pythonType /\<\l\w*\>\.\zs\<_*\u\w*\>/
hi def pythonType ctermfg=214

" Match 'self'
syn keyword pythonSelf self
hi def pythonSelf ctermfg=253 cterm=italic

" Match builtin types
" ref: https://docs.python.org/3/library/stdtypes.html
" ref: https://docs.python.org/3/library/functions.html (search for 'class ')
syn keyword pythonBuiltinType object type
syn keyword pythonBuiltinType bool
syn keyword pythonBuiltinType int float complex
syn keyword pythonBuiltinType list tuple range
syn keyword pythonBuiltinType str
syn keyword pythonBuiltinType bytes bytearray memoryview
syn keyword pythonBuiltinType set frozenset
syn keyword pythonBuiltinType dict
hi def pythonBuiltinType ctermfg=131

" FIXME: No idea where to define all python highlights in a single place... Let's add more here...
hi pythonFunction ctermfg=33 cterm=bold
