; This file defines custom queries for highlighting
;; extends

; Builtin module keywords in module path or visibility modifier
; e.g. `use super::foo;`
;           ^^^^^
; e.g. `pub(super) hello …`
;           ^^^^^
(scoped_identifier
  [
    (super)
    (self)
    (crate)
  ] @module.builtin)
(scoped_use_list path: (crate) @module.builtin)
(visibility_modifier
  [
    (super)
    (self)
    (crate)
  ] @module.builtin)
; Same but for visibility modifier, at crate-level (larger scope)
(visibility_modifier
  [
    (crate)
  ] @module.builtin.crate)

"pub" @keyword.public
