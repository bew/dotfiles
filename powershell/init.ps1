# https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/optimize-shell

# NOTE: `$PSScriptRoot` is path of the current file, useful for relative imports!
. $PSScriptRoot\env.ps1
. $PSScriptRoot\aliases_and_short_funcs.ps1
. $PSScriptRoot\prompt.ps1
. $PSScriptRoot\mappings.ps1
. $PSScriptRoot\plugins.ps1

# `$?` (in prompt) is only reliable when commands immediately stops!
$ErrorActionPreference = "Stop"
