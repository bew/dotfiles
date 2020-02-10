
" We must add 'String' at the end of the region name to avoid python
" indentation in this region
" Handle 'grammar = """' -> '"""'
syn region  pyrserGrammarString start=#grammar\s*=\s*\zs\z('''\|"""\)# end="\z1" keepend
			\ contains=pyrserRule,pyrserRuleBlock,pyrserCommentMultiline,pyrserCommentOneline

" There is a space at the beginning to prevent accidental matching in python
" source (or this will be very rare)
" Handle 'my_rule = '
syn match   pyrserRule / \w\+\ze\s*=\s*/ contained nextgroup=pyrserRuleBlock

syn region  pyrserRuleBlock start=/\[/ end=/\]/ skip=/\\\]/ contained
			\ contains=pyrserRuleBlock,pyrserHook,pyrserQuotes,pyrserModifier,pyrserName,pyrserScope,pyrserCommentMultiline,pyrserCommentOneline

" Handle '#my_hook(args)' & '#Base.my_hook(args)'
syn match   pyrserHook /\#\(\w\|\.\)\+(.*)/ contained
syn region  pyrserQuotes start=/\z(['"]\)/ end="\z1" skip="\\\z1" contained

" Handle '?' & '*' & '+'
syn match   pyrserModifier /?\|\*\|+/ contained

syn keyword pyrserScope __scope__ contained

" Handle ':name' & ':>name'
syn match   pyrserName /:\(\s*>\)\?\s*\w\+/ contained

syn region  pyrserCommentMultiline start=#/\*# end=#\*/# contains=TOP contained
syn match   pyrserCommentOneline #//.*# contains=pythonTodo contained

hi link pyrserRule Type
hi link pyrserHook pythonFunction
hi link pyrserQuotes pythonString
hi link pyrserName PreProc
hi link pyrserModifier PreProc

hi link pyrserCommentMultiline pythonComment
hi link pyrserCommentOneline pythonComment

hi pyrserScope cterm=italic
