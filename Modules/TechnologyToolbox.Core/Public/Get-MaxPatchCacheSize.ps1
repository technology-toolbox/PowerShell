<#
.SYNOPSIS
Gets the maximum percentage of disk space the Windows installer can use for the
cache of old files.

.DESCRIPTION
If this per-machine system policy is set to a value greater than 0, Windows
Installer saves older versions of files in a cache when a patch is applied to an
application.

.LINK
http://msdn.microsoft.com/en-us/library/windows/desktop/aa369798.aspx

.LINK
http://www.technologytoolbox.com/blog/jjameson/archive/2010/04/30/save-significant-disk-space-by-setting-maxpatchcachesize-to-0.aspx

.EXAMPLE
.\Get-MaxPatchCacheSize.ps1
0

Description
-----------
In this example, the MaxPatchCacheSize policy has previously been set to 0 (to
indicate that no additional files should be saved).
#>
function Get-MaxPatchCacheSize {
    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
    }

    Process {
        [string] $installerPath = "HKLM:\Software\Policies\Microsoft\Windows\Installer"

        Get-ItemProperty -Path $installerPath -Name MaxPatchCacheSize |
            ForEach-Object { $_.MaxPatchCacheSize }
    }
}