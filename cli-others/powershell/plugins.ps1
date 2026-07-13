function Test-CommandExists {
    # note: taken from https://devblogs.microsoft.com/scripting/use-a-powershell-function-to-see-if-a-command-exists/
    param(
        [Parameter(Mandatory, HelpMessage = "The command to check for existance")]
        [string]$command
    )
    $oldActionPref = $ErrorActionPreference
    $ErrorActionPreference = "stop"

    try {
        if (Get-Command $command) {
            $true
        }
    }
    catch {
        $false
    }
    finally {
        $ErrorActionPreference = $oldActionPref
    }
}

if (Test-CommandExists "zoxide") {
    # ref: https://github.com/ajeetdsouza/zoxide
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    Write-Host ":: zoxide plugin initialized"
}
