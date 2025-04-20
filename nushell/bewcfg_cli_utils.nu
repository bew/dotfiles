export def sort-by-closure [
  predicate: closure
  # Activate and forward the options to `sort-by`
  # when https://github.com/nushell/nushell/issues/7260 is released
  # --reverse(-r)     # Sort in reverse order
  # --ignore-case(-i) # Sort string-based columns case-insensitively
  # --natural(-n)     # Sort alphanumeric string-based columns naturally
]: table -> table {
  (
    insert __predicate $predicate
    | sort-by __predicate
    | reject __predicate
  )
}

# FIXME: Currently broken @ v0.87.x (only works for list/tables)
# See: https://discord.com/channels/601130461678272522/614593951969574961/1178454822991708240
export def len []: any -> int {
  let input_type = $in | describe --detailed | get type
  match ($input_type) {
    "string" => {
      $in | str stats | get chars
    }
    "list" | "table" => {
      $in | length
    }
    _ => (
      error make {
        msg: $"Don't know how to get length of type ($input_type)"
        label: {
          text: "this input has a length?"
          span: (metadata $in).span
        }
      }
    )
  }
}
