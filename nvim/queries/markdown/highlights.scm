;; extends

; Highlight strong/italic delimiters specially to be different from the rest
; NOTE: Ensure it takes precedence (base prio is 100)
(fenced_code_block_delimiter) @punctuation.delimiter @markup.raw.delimiter (#set! "priority" 105)
