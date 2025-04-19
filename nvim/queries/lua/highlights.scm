;; extends

; Distinguish foo in `{ foo = 1 }` vs `vim.g.foo`
; NOTE: this is the default in v0.11.0
(field
  name: (identifier) @property)
