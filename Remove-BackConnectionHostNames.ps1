<#
.SYNOPSIS
Removes the specified host names from the BackConnectionHostNames registry
value.

.DESCRIPTION
The BackConnectionHostNames registry value is used to bypass the loopback
security check for specific host names.

.LINK
http://support.microsoft.com/kb/896861

.EXAMPLE
.\Remove-BackConnectionHostNames.ps1 fabrikam-local

#>
param(
    [parameter(Mandatory=$true)]
    [string[]] $HostNames)

$ErrorActionPreference = "Stop"

[string] $registryPath = "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

$registryKey = Get-Item -Path $registryPath

$backConnectionHostNames = $registryKey.GetValue("BackConnectionHostNames")

If ($backConnectionHostNames -eq $null)
{
    Exit
}

$hostNameList = New-Object System.Collections.ArrayList

$backConnectionHostNames -Split [System.Environment]::NewLine | foreach {
    $hostNameList.Add($_) | Out-Null
}

[int] $hostNamesRemoved = 0

$HostNames | foreach {
    [string] $hostName = $_
    
    for ([int] $i = 0; $i -lt $hostNameList.Count; $i++)
    {
        If ([string]::Compare($hostNameList[$i], $hostName, $true) -eq 0)
        {                
            $hostNameList.RemoveAt($i)
            $i--
            
            $hostNamesRemoved++
        }
    }
}

If ($hostNamesRemoved -eq 0)
{
    Write-Host ("No changes to the BackConnectionHostNames value are" `
        + " necessary.")
    
    Exit
}

If ($hostNameList.Count -eq 0)
{
    Remove-ItemProperty -Path $registryPath -Name BackConnectionHostNames
}
Else
{
    $hostNameList.Sort()
    
    [string] $delimitedHostNames =
        $hostNameList -Join [System.Environment]::NewLine
        
    Set-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
        -Value $delimitedHostNames | Out-Null
}

Write-Host -Fore Green ("Successfully removed host names ($HostNames) from" `
    + " BackConnectionHostNames.")