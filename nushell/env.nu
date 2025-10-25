# Nushell Environment Config File
# vim:set ft=nu.conf:

# Directories to search when using `source` or `use`
$env.NU_LIB_DIRS = [
  $nu.default-config-dir
]

# Directories to search for plugin binaries when registering plugins
$env.NU_PLUGIN_DIRS = [
  ($nu.default-config-dir | path join "plugins") # add <nushell-config-dir>/plugins
]

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str join (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str join (char esep) }
  }
}

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
