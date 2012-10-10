param(
  [int] $MaxPercentageOfDiskSpace = $(Read-Host -Prompt "MaxPercentageOfDiskSpace"))
  
$ErrorActionPreference = "Stop"

[int] $maxPatchCacheSize = $MaxPercentageOfDiskSpace

[string] $installerPath = "HKLM:\Software\Policies\Microsoft\Windows\Installer"

$installerKey = Get-Item -Path $installerPath

$currentMaxPatchCacheSize = $installerKey.GetValue("MaxPatchCacheSize")

If ($currentMaxPatchCacheSize -eq $null)
{
    New-ItemProperty -Path $installerPath -Name MaxPatchCacheSize `
        -PropertyType DWord -Value $maxPatchCacheSize
}
ElseIf ($currentMaxPatchCacheSize -eq $maxPatchCacheSize)
{
    Write-Host ("MaxPatchCacheSize is already set to {0}." -f $maxPatchCacheSize)
    Exit
}
Else
{
    Set-ItemProperty -Path $installerPath -Name MaxPatchCacheSize `
        -Value $maxPatchCacheSize | Out-Null
}

Write-Host -Fore Green ("Successfully set MaxPatchCacheSize to {0}." `
    -f $maxPatchCacheSize)
