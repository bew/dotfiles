# https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/optimize-shell

# NOTE: Use `[System.Console]::ReadKey()` to check what key is recognized
# Some keys are not recognized by PSReadLine :/ (like Alt+$ Alt+%)

Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete

Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory

Set-PSReadLineKeyHandler -Chord Alt+h -Function BackwardChar
Set-PSReadLineKeyHandler -Chord Alt+l -Function ForwardChar
Set-PSReadLineKeyHandler -Chord Alt+w -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Alt+b -Function BackwardWord

# (needed since the default is Alt+h and I used it for movement)
Set-PSReadLineKeyHandler -Chord Alt+i -Function ShowParameterHelp

# For Ctrl+j
Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AcceptLine

#-----------------

New-Alias -Name e nvim

function Set-Location-New-Directory {
  # Use strict argument handling
  # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute
  [CmdletBinding()]
  # https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/parameter-attribute-declaration
  Param(
    [Parameter(Mandatory, HelpMessage="Directory path to create and cd into")]
    $dir
  )

  If (Test-Path $dir -PathType Container) {
    Write-Host "info: directory '$dir' already exists"
  } Else {
    New-Item -ItemType Directory $dir | Out-Null # discard output
    Write-Host "info: created directory '$dir'"
  }
  Set-Location $dir
}
New-Alias -Name mkcd Set-Location-New-Directory
