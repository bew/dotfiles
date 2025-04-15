# NOTE: Powershell aliases are only command name aliases, we can't pass 'default' arguments to the command in an alias.
#   We must use a tiny wrapper function for that.
# REF: https://stackoverflow.com/questions/4166370/how-can-i-write-a-powershell-alias-with-arguments-in-the-middle

New-Alias -Name e nvim
New-Alias -Name tf terraform
New-Alias -Name j just

New-Alias -Name g git
function gnp {
    git --no-pager $args
}

function gdiff {
    git diff --no-index $args
}

# `eza` configuration:
$env:EZA_COLORS =  "" # init
$env:EZA_COLORS +=  "da=38;5;243:" # darker
$env:EZA_COLORS +=  "uu=38;5;239:gu=38;5;239:" # darker username & group
# Color file sizes by order of magnitude
$env:EZA_COLORS +=  "nb=38;5;239:ub=38;5;241:"    #  0  -> <1KB : grey
$env:EZA_COLORS +=  "nk=38;5;29:uk=38;5;100:"     # 1KB -> <1MB : green
$env:EZA_COLORS +=  "nm=38;5;26:um=38;5;32:"      # 1MB -> <1GB : blue
$env:EZA_COLORS +=  "ng=38;5;130:ug=38;5;166;1:"  # 1GB -> <1TB : orange
$env:EZA_COLORS +=  "nt=38;5;160:ut=38;5;197;1:"  # 1TB -> +++  : red
# Darker per missions (shades of grey)
$env:EZA_COLORS +=  "ur=38;5;240:uw=38;5;244:ux=38;5;248:ue=38;5;248:" # user permissions
$env:EZA_COLORS +=  "gr=38;5;240:gw=38;5;244:gx=38;5;248:" # group permissions
$env:EZA_COLORS +=  "tr=38;5;240:tw=38;5;244:tx=38;5;248:" # other permissions
$env:EZA_COLORS +=  "xa=38;5;24:" # xattr marker ('@')
$env:EZA_COLORS +=  "xx=38;5;240:" # punctuation ('-')

function eza-common {
    eza --group-directories-first @args
}
function ll {
    eza-common -l @args
}
function l {
    eza-common -la @args
}
function ltre {
    l --tree --git-ignore @args
}
function lltre {
    ll --tree --git-ignore @args
}

function Set-Location-New-Directory {
    # https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/parameter-attribute-declaration
    Param(
        [Parameter(Mandatory, HelpMessage = "Directory path to create and cd into")]
        [string]$dir
    )

    If (Test-Path $dir -PathType Container) {
        Write-Host "info: directory '$dir' already exists"
    }
    Else {
        New-Item -ItemType Directory $dir | Out-Null # discard output
        Write-Host "info: created directory '$dir'"
    }
    Set-Location $dir
}
New-Alias -Name mkcd Set-Location-New-Directory
New-Alias -Name mkd mkdir

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Replicate basic functionality of `touch` on UNIX:
# Create empty file if it doesn't exist, else update file access time
#
# Copied from: https://superuser.com/a/571154/536847
function touch {
    param(
        [Parameter(Mandatory, HelpMessage = "Filepath to create/touch")]
        [string]$file
    )
    if (Test-Path $file) {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    } else {
        New-Item $file
    }
}

function lastcmd {
    if ((Get-History).Count -eq 0) {
        Write-Error "No last command, no history!"
        return
    }
    $last = (Get-History)[-1]
    Write-Host "Command: $($last.CommandLine)"
    $status_msg = & {
        [string]$status = $last.ExecutionStatus
        switch ($status) {
            "Failed" { (fmt red) + (fmt bold) + $status + (fmt reset) }
            "Completed" { (fmt green) + (fmt bold) + $status + (fmt reset) }
            Default { $status }
        }
    }
    if ($ErrorActionPreference -ne "Stop") {
        # Execution status is only reliable when 'Stop'
        $status_msg += " ($(fmt bold)UNRELIABLE$(fmt reset), `$ErrorActionPreference is $(fmt red)${ErrorActionPreference}$(fmt reset))"
    }
    Write-Host "Status: $status_msg"
    $duration_for_humans = & {
        $hd = ""
        $d = $last.Duration
        if ($d.Hours -ge 1) {
            $hd += [string]($d.Hours) + "h "
        }
        if ($d.Minutes -ge 1) {
            $hd += [string]($d.Minutes) + "m "
        }
        if ($d.Seconds -ge 1) {
            $hd += [string]($d.Seconds) + "s "
        }
        if ($d.Milliseconds -ge 1) {
            $hd += [string]($d.Milliseconds) + "ms "
        }
        $hd
    }
    Write-Host "Duration: $duration_for_humans"
}

# From: https://stackoverflow.com/a/55226209/5655255
function Save-Clipboard-As-Image-File {
    param($name)

    $filepath="$(pwd)\${name}.png"
    Add-Type -AssemblyName System.Windows.Forms
    $clipboard = [System.Windows.Forms.Clipboard]::GetDataObject()
    if ($clipboard.ContainsImage()) {
        [System.Drawing.Bitmap]$clipboard.getimage().Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Clipboard content saved as $filepath"
    } else {
        Write-Error "Clipboard does not contains image data"
    }
}
