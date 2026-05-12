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

; For sql query like `sql_query = "SELECT ..."`
(expression_statement
  (assignment
    left: (identifier) @_name
    right: (string
      (string_content) @injection.content
    )
  )
  (#match? @_name "sql")
  (#set! injection.language "sql")
)
