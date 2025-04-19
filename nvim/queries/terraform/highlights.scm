; inherits: terraform

; Replicate the Terraform specific references,
; to be highlighted in conditions like `var.foo == "bar"`
;
; Inspired from https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/terraform/highlights.scm
;
; `{local,module,data,var,output}.foobar`
(binary_operation
  (variable_expr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "data" "var" "local" "module" "output")
  )
  (get_attr
    (identifier) @variable.member
  )
)
; `path.{root,cwd,module}`
(binary_operation
  (variable_expr
    (identifier) @type.builtin
    (#eq? @type.builtin "path")
  )
  (get_attr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "root" "cwd" "module")
  )
)
; `terraform.workspace`
(binary_operation
  (variable_expr
    (identifier) @type.builtin
    (#eq? @type.builtin "terraform")
  )
  (get_attr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "workspace")
  )
)
