$env:GIT_EDITOR = "nvim"

# Make sure `less` opens in altscreen buffer (to not pollute terminal scrollback)
# and displays ANSI colors nicely
$env:LESS = "-R +X"
# Customize less's keybindings
$env:LESSKEYIN = Resolve-Path $PSScriptRoot\..\less\lesskey-bew
