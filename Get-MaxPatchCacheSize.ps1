$ErrorActionPreference = "Stop"

[string] $installerPath = "HKLM:\Software\Policies\Microsoft\Windows\Installer"

Get-ItemProperty -Path $installerPath -Name MaxPatchCacheSize |
    ForEach-Object { $_.MaxPatchCacheSize }