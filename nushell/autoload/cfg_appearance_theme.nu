# -------------------------------------
# Themes/Colors and Syntax Highlighting
# -------------------------------------
#
# For more information on defining custom themes, see
# https://www.nushell.sh/book/coloring_and_theming.html
#
# Use and/or contribute to the theme collection at:
# https://github.com/nushell/nu_scripts/tree/main/themes
#
# note: this is usually set through a theme provided by a record in a custom command.
# For instance, the standard library contains two "starter" theme commands:
# "dark-theme" and "light-theme"
#
# For example:
# ```nu
# use std/config dark-theme
# $env.config.color_config = (dark-theme)
# ```
#
# Or, individual color settings can be configured or overridden.
#
# Values can be one of:
# - A color name such as "red" (see `ansi -l` for a list)
# - A color RGB value in the form of "#C4C9C6"
# - A record including:
#   * `fg` (color)
#   * `bg` (color)
#   * `attr`: a string with one or more of:
#     - 'n': normal
#     - 'b': bold
#     - 'u': underline
#     - 'r': reverse
#     - 'i': italics
#     - 'd': dimmed
#
# foreground, background, and cursor colors are not handled by Nushell, but can be used by
# custom-commands such as `theme` from the nu_scripts repository.
# That `theme` command can be used to set the terminal foreground, background, and cursor colors.
# ```nu
# $env.config.color_config.foreground
# $env.config.color_config.background
# $env.config.color_config.cursor
# ```

$env.config.color_config = {
  # color for nushell primitives
  separator: white
  leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
  header: green_bold
  empty: blue

  # Closures can be used to choose colors for specific values.
  # The value (in this case, a bool) is piped into the closure.
  # eg) {|| if $in { 'light_cyan' } else { 'light_gray' } }
  bool: light_cyan
  int: white
  filesize: cyan
  duration: white
  date: purple
  range: white
  float: white
  string: white
  nothing: white
  binary: white
  cell-path: white
  row_index: green_bold
  record: white
  list: white
  block: white
  hints: dark_gray
  search_result: {bg: red fg: default}

  # 'shapes' are used to change the cli syntax highlighting
  shape_and: purple_bold
  shape_binary: purple_bold
  shape_block: blue_bold
  shape_bool: light_cyan
  shape_closure: green_bold
  shape_custom: green
  shape_datetime: cyan_bold
  shape_directory: cyan
  shape_external: cyan
  shape_externalarg: green_bold
  shape_filepath: cyan
  shape_flag: blue_bold
  shape_float: purple_bold
  shape_garbage: { fg: white bg: red attr: b}
  shape_globpattern: cyan_bold
  shape_int: purple_bold
  shape_internalcall: cyan_bold
  shape_list: cyan_bold
  shape_literal: blue
  shape_match_pattern: green
  shape_matching_brackets: { attr: u }
  shape_nothing: light_cyan
  shape_operator: yellow
  shape_or: purple_bold
  shape_pipe: purple_bold
  shape_range: yellow_bold
  shape_record: cyan_bold
  shape_redirection: purple_bold
  shape_signature: green_bold
  shape_string: green
  shape_string_interpolation: cyan_bold
  shape_table: blue_bold
  shape_variable: purple
  shape_vardecl: purple
}

# ------------------------------------------------

# MAYBE: some options that might be intereseting...

# highlight_resolved_externals (bool): Style confirmed external commands differently.
# true: Apply shape_external_resolved color to commands found on PATH.
# false: Apply shape_external to all externals based on parsing position.
# $env.config.highlight_resolved_externals = false # (default: false)
