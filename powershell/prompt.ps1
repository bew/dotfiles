# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_prompts
# https://learn.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup

function Get-DefaultPrompt {
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}

# Terminal style format
# TODO: make this work: `fmt red bold { "this in bold red, and reset after" }`
function fmt {
    Param(
        [Parameter(Mandatory, HelpMessage = "Terminal style format")]
        [string]$fmt
    )
    # Convert a few basic styles by name, otherwise take as-is
    $fmt = switch ($fmt) {
        "reset" { "0" }
        "bold" { "1" }
        "red" { "31" }
        "green" { "32" }
        "yellow" { "33" }
        Default { $fmt }
    }
    [char]27 + "[" + $fmt + "m"
}

# Foreground color in the 256 color palette
# https://www.ditig.com/256-colors-cheat-sheet
function fg256 {
    Param(
        [Parameter(Mandatory, HelpMessage = "Color ID in 256 color palette")]
        [string]$color
    )
    fmt ("38;5;" + $color)
}

function promptsegment-short-cwd {
    $fmt_path_part = fg256 "208"
    $fmt_path_sep = (fmt bold) + (fg256 "160")

    # note: `& { ... }` directly executes the given ScriptBlock, allowing to 'group' some code
    $small_cwd_parts = & {
        $path = $executionContext.SessionState.Path.CurrentLocation
        # $drive = $path | Split-Path -Qualifer
        $current_dir_name = $path | Split-Path -Leaf
        $parent_dir = $path | Split-Path -Parent
        if ($parent_dir.Length -eq 0) {
            @($path)
        } else {
            $parent_dir_name = $parent_dir | Split-Path -Leaf
            @($parent_dir_name.TrimEnd("\"), $current_dir_name)
        }
    }
    $small_cwd_styled_parts = $small_cwd_parts.foreach{ $fmt_path_part + $_ + (fmt reset) }
    $small_cwd_styled_parts -join ($fmt_path_sep + "\")
}

function promptsegment-ctx-sanity {
    $styled = ""
    if ($ErrorActionPreference -ne "Stop") {
        $styled += (fmt yellow) + (fmt bold) + "⚠ " + (fmt reset)
    }
    $styled
}

function promptsegment-status {
    param([bool]$last_status)
    $styled = ""
    if (!$last_status) {
        $styled += (fmt red) + (fmt bold) + "\FAIL/ " + (fmt reset)
    }
    $styled
}

function Prompt {
    # MUST be first, for `$?` to be useful
    $last_status = promptsegment-status $?
    $ctx_sanity = promptsegment-ctx-sanity
    $short_cwd = promptsegment-short-cwd
    $ending = ">" * ($nestedPromptLevel + 1)

    $ctx_sanity + $last_status + $short_cwd + $ending + " "
}
# This is necessary to color the end of the prompt Red when the command is invalid.
# (value of that option seems to be reset to default whenever the `Prompt` function is set)
Set-PSReadLineOption -PromptText "> "
