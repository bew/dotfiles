# PowerShell config

## Bootstrap

The default location of the config file used by `powershell` cannot be changed, but we can source other files!
Put in `$PROFILE` file:
```pwsh
. $env:XDG_CONFIG_HOME\powershell\PowerShell_profile.ps1
```
(need to set env var `$XDG_CONFIG_HOME` globally)

---
