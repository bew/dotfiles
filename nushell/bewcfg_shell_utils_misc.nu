# Returns the length of the input
# Unlike the default `length` it works the same way for string & list/table
export def len []: [
  nothing -> nothing,
  any -> int,
] {
  let val = $in
  let input_type = $val | describe --detailed | get type
  match ($input_type) {
    "nothing" => {
      error make { msg: "Cannot get length of nothing" }
    }
    "string" => {
      $val | str stats | get chars
    }
    "list" | "table" => {
      $val | length
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
