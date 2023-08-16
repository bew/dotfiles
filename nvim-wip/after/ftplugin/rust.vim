" Force disable auto-comment-leader on 'o' or 'O'.
setlocal formatoptions-=o

" TODO: Remap some insert-mode keys to disable/enable auto-pairing based on
"       the presence of char before or not:
"       Example:
"       * `impl│`    then `<`  should become `impl<│>`     (autopair)
"       * `if foo │` then `<`  should become `if foo <│`   (no autopair)
"       * `foo: &│`  then `'`  should become `foo: &'│`    (no autopair)
"       * `just(│)`  then `'`  should become `just('│')`   (autopair)
