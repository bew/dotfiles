;; extends

; `None` in simple union type
; e.g: `str | None`
(type
  (binary_operator
    right: (none) @type.builtin))

; `None` in a complex union type
; e.g: `list[str] | None`
(type (none) @type.builtin)
