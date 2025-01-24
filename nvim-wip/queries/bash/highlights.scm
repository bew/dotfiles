;; extends

; Give higher priority to variable names, to ensure they stand out in a string.
(variable_name) @variable
(simple_expansion
  (special_variable_name) @variable.special
  (#set! "priority" 105))
(simple_expansion
  (variable_name) @variable
  (#set! "priority" 105))
; Help short (one-char) variables (like $1) stand out with custom styling
(simple_expansion
  (variable_name) @variable.short
  (#lua-match? @variable.short "^.$")
  (#set! "priority" 105))

; Give -o --option params special treatment
(command
  argument: [
    (word) @variable.option_parameter
    (concatenation
      (word) @variable.option_parameter)
  ]
  ; Starts with `-` (but is not only that)
  (#lua-match? @variable.option_parameter "^\-.?"))
(declaration_command
  (word) @variable.option_parameter
  ; Starts with `-` (but is not only that)
  (#lua-match? @variable.option_parameter "^\-.?"))
