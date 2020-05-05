" Specifies the default alignment to use when inserting comments.
let g:NERDDefaultAlign = 'left'

" Add some spaces between the comment delimiter (e.g: `#`) and the commented text
let g:NERDSpaceDelims = 1

" When uncommenting an empty line some whitespace may be left as a result of
" alignment padding. With this option enabled any trailing whitespace will be
" deleted when uncommenting a line.
let g:NERDTrimTrailingWhitespace = 1

" when g:NERDSpaceDelims==1, then NERDComment results in double space
let g:NERDCustomDelimiters = {
    \ 'python': { 'left': '#' }
    \ }
