<#
.SYNOPSIS
Adds the specified host names to the BackConnectionHostNames registry
value.

.DESCRIPTION
The BackConnectionHostNames registry value is used to bypass the loopback
security check for specific host names.

.LINK
http://support.microsoft.com/kb/896861

.EXAMPLE
.\Add-BackConnectionHostNames.ps1 fabrikam-local, www-local.fabrikam.com

#>
param(
    [parameter(Mandatory=$true)]
    [string[]] $HostNames)

$ErrorActionPreference = "Stop"

If ($HostNames.Length -eq 1)
{
    Write-Host "Adding host name ($HostNames) to BackConnectionHostNames..."
}
Else
{
    Write-Host ("Adding $($HostNames.Length) host names ($HostNames) to" `
        + " BackConnectionHostNames...")
}

[string] $registryPath = "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

$registryKey = Get-Item -Path $registryPath

$backConnectionHostNames = $registryKey.GetValue("BackConnectionHostNames")

If ($backConnectionHostNames -eq $null)
{
    $hostNameList = $HostNames | Sort

    [string] $delimitedHostNames =
        $hostNameList -Join [System.Environment]::NewLine

    New-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
        -PropertyType MultiString -Value $delimitedHostNames | Out-Null
}
Else
{
    $hostNameList = New-Object System.Collections.ArrayList

    $backConnectionHostNames -Split [System.Environment]::NewLine | foreach {
        $hostNameList.Add($_) | Out-Null
    }

    [int] $hostNamesAdded = 0

    $HostNames | foreach {
        [string] $hostName = $_

        [bool] $hostNameFound = $false

        $hostNameList | foreach {
            If ([string]::Compare($_, $hostName, $true) -eq 0)
            {
                Write-Host ("The host name ($hostName) is already specified" `
                    + " in BackConnectionHostNames.")

                $hostNameFound = $true
                return
            }
        }

        If ($hostNameFound -eq $false)
        {
            $hostNameList.Add($hostName) | Out-Null

            $hostNamesAdded++
        }
    }

    If ($hostNamesAdded -eq 0)
    {
        Write-Host ("No changes to the BackConnectionHostNames value are" `
            + " necessary.")

        Exit
    }
    Else
    {
        $hostNameList.Sort()

        [string] $delimitedHostNames =
            $hostNameList -Join [System.Environment]::NewLine

        Set-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
            -Value $delimitedHostNames | Out-Null
    }
}

Write-Host -Fore Green ("Successfully added host names ($HostNames) to" `
    + " BackConnectionHostNames.")
