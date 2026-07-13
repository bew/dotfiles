# Use `[System.Console]::ReadKey()` to check what key is recognized
# (NOTE: Some keys are not recognized by PSReadLine :/ (like Alt+$ Alt+%))
#
# See already registered key handlers with `Alt+?` then the key
# See existing PSReadLine functions with `Get-PSReadLineKeyHandler`

# Disable dangerous default `Escape` KeyHandler which deletes everything without ability to undo (⚠)
Remove-PSReadLineKeyHandler -Key Escape
Set-PSReadLineKeyHandler -Key Escape -ScriptBlock {} # do nothing

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

Set-PSReadLineKeyHandler -Key Alt+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Key Alt+j -Function NextHistory

Set-PSReadLineKeyHandler -Key Alt+h -Function BackwardChar
Set-PSReadLineKeyHandler -Key Alt+l -Function ForwardChar
Set-PSReadLineKeyHandler -Key Alt+w -Function ForwardWord
Set-PSReadLineKeyHandler -Key Alt+b -Function BackwardWord

# We can't use Alt+$ in Powershell and Ctrl+Alt+e is not recognized in VSCode,
# so this will do as a last-resort to go the EOL..:
Set-PSReadLineKeyHandler -Key Alt+e -Function EndOfLine
Set-PSReadLineKeyHandler -Key Ctrl+e -Function EndOfLine

Set-PSReadLineKeyHandler -Key Ctrl+j     -Function AcceptLine
Set-PSReadLineKeyHandler -Key Ctrl+Enter -Function AcceptLine # necessary on Linux (`Ctrl+j` is recognized as `Enter`)

Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardDeleteLine
Set-PSReadLineKeyHandler -Key Ctrl+w        -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function BackwardKillWord

Set-PSReadLineKeyHandler -Key Alt+u  -Function Undo
Set-PSReadLineKeyHandler -Key Alt+U  -Function Redo

# Seems to not delete char, but does exit when cursor is at BOL.
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

# Custom key actions
# https://learn.microsoft.com/en-us/dotnet/api/microsoft.powershell.psconsolereadline
#
# Sample of some advanced shell mapping configs ❤:
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
# Nice inspirations:
# https://community.spiceworks.com/topic/1570654-what-s-in-your-powershell-profile

# Lines that don't start with a space will be saved in history
Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)
    return $line.Length -ge 1 -and $line[0] -ne " "
}

function bew-BackupLine {
    $line = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$null)
    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
}
function bew-BackupLineAndRunNoHistory {
    param ([string]$line_to_run)
    # backup line to history
    bew-BackupLine

    # Prepend line to run with a space so it won't be included in history
    $line_to_run = " " + $line_to_run
    # Run the command, removing previous text
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line_to_run)
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Alt+g -BriefDescription GitStatus -ScriptBlock {
    bew-BackupLineAndRunNoHistory("git status")
}

Set-PSReadLineKeyHandler -Key Alt+l -BriefDescription GoRightOrGitLog -ScriptBlock {
    $line = $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($cursor -lt $line.Length) { # <
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor+1)
    } else {
        bew-BackupLineAndRunNoHistory("git la")
    }
}

Set-PSReadLineKeyHandler -Key Alt+d -BriefDescription GitDiff -ScriptBlock {
    bew-BackupLineAndRunNoHistory("git d")
}

Set-PSReadLineKeyHandler -Key Alt+D -BriefDescription GitDiffCached -ScriptBlock {
    bew-BackupLineAndRunNoHistory("git dc")
}

Set-PSReadLineKeyHandler -Key Alt+s -BriefDescription SaveLineForLater -ScriptBlock {
    bew-BackupLine
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

# (note: default mapping for this is `Alt+h` but I already use that for cursor movement)
# Set-PSReadLineKeyHandler -Key Alt+i -Function ShowParameterHelp
# => Disabled as not available in PowerShell 5..
