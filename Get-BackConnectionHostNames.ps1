<#
.SYNOPSIS
Gets the list of host names specified in the BackConnectionHostNames registry
value.

.DESCRIPTION
The BackConnectionHostNames registry value is used to bypass the loopback
security check for specific host names.

.LINK
http://support.microsoft.com/kb/896861

.EXAMPLE
Get-BackConnectionHostNames

Hostname
--------
fabrikam-local
www-local.fabrikam.com
#>
[string] $registryPath = "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

$registryKey = Get-Item -Path $registryPath

$backConnectionHostNames = $registryKey.GetValue("BackConnectionHostNames")

If ($backConnectionHostNames -ne $null)
{
    $backConnectionHostNames | foreach {
        $properties = @{
            HostName = $_
        }

        New-Object PSObject -Property $properties
    }
}