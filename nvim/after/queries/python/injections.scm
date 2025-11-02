; This file defines custom queries for language injection
;; extends

; For sql function call like `cur.execute("SELECT ...")`
(call
  function: (attribute
    object: (identifier) @_obj
    attribute: (identifier) @_attr
  )
  arguments: (argument_list
    . ; the string must be the first arg!
    (string
      (string_content) @injection.content
    )
  )
  (#any-of? @_obj "cur" "cursor")
  (#eq? @_attr "execute")
  (#set! injection.language "sql")
)
