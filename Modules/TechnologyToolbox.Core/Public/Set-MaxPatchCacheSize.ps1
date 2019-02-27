<#
.SYNOPSIS
Sets the maximum percentage of disk space the Windows installer can use for the
cache of old files.

.DESCRIPTION
If this per-machine system policy is set to a value greater than 0, Windows
Installer saves older versions of files in a cache when a patch is applied to an
application.

.PARAMETER MaxPercentageOfDiskSpace
The maximum percentage of disk space the installer can use for the cache of old
files.

.LINK
http://msdn.microsoft.com/en-us/library/windows/desktop/aa369798.aspx

.LINK
http://www.technologytoolbox.com/blog/jjameson/archive/2010/04/30/save-significant-disk-space-by-setting-maxpatchcachesize-to-0.aspx

.EXAMPLE
.\Set-MaxPatchCacheSize.ps1 0

Description
-----------
Sets the value of the MaxPatchCacheSize policy to 0 to indicate that no
additional files should be saved.

.NOTES
This script must be run with administrator privileges.
#>
function Set-MaxPatchCacheSize {
    param(
        [parameter(Mandatory = $true)]
        [int] $MaxPercentageOfDiskSpace)

    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
    }

    Process {
        [int] $maxPatchCacheSize = $MaxPercentageOfDiskSpace

        [string] $installerPath = "HKLM:\Software\Policies\Microsoft\Windows\Installer"

        $installerKey = Get-Item -Path $installerPath -EA 0

        If ($installerKey -eq $null) {
            $installerKey = New-Item -Path $installerPath
        }

        $currentMaxPatchCacheSize = $installerKey.GetValue("MaxPatchCacheSize")

        If ($currentMaxPatchCacheSize -eq $null) {
            New-ItemProperty -Path $installerPath -Name MaxPatchCacheSize `
                -PropertyType DWord -Value $maxPatchCacheSize | Out-Null
        }
        ElseIf ($currentMaxPatchCacheSize -eq $maxPatchCacheSize) {
            Write-Verbose ("MaxPatchCacheSize is already set to {0}." -f $maxPatchCacheSize)
            return
        }
        Else {
            Set-ItemProperty -Path $installerPath -Name MaxPatchCacheSize `
                -Value $maxPatchCacheSize | Out-Null
        }

        Write-Host -Fore Green ("Successfully set MaxPatchCacheSize to {0}." `
                -f $maxPatchCacheSize)
    }
}