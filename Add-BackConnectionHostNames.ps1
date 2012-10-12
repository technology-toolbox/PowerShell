<#
.SYNOPSIS
Adds one or more host names to the BackConnectionHostNames registry value.

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

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    [int] $hostNamesAdded = 0

    [Collections.ArrayList] $hostNameList = New-Object Collections.ArrayList

    [string] $registryPath = "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

    $registryKey = Get-Item -Path $registryPath

    $registryValue = $registryKey.GetValue("BackConnectionHostNames")

    $registryValue -Split [System.Environment]::NewLine | foreach {
        $hostNameList.Add($_) | Out-Null
    }
}

process
{
    $HostNames | foreach {
        [string] $hostName = $_

        [bool] $isHostNameInList = $false

        $hostNameList | foreach {
            If ([string]::Compare($_, $hostName, $true) -eq 0)
            {
                Write-Host ("The host name ($hostName) is already specified" `
                    + " in the BackConnectionHostNames list.")

                $isHostNameInList = $true
                return
            }
        }

        If ($isHostNameInList -eq $false)
        {
            Write-Host ("Adding host name ($hostName) to" `
                + " BackConnectionHostNames list...")

            $hostNameList.Add($hostName) | Out-Null

            $hostNamesAdded++
        }
    }
}

end
{
    If ($hostNamesAdded -eq 0)
    {
        Write-Host ("No changes to the BackConnectionHostNames value are" `
            + " necessary.")

        return
    }
    Else
    {
        $hostNameList.Sort()

        for ([int] $i = 0; $i -lt $hostNameList.Count; $i++)
        {
            If ([string]::IsNullOrEmpty($hostNameList[$i]) -eq $true)
            {
                $hostNameList.RemoveAt($i)
                $i--
            }
        }

        [string] $delimitedHostNames =
            $hostNameList -Join [System.Environment]::NewLine

        If ($registryValue -eq $null)
        {
            New-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
                -PropertyType MultiString -Value $delimitedHostNames | Out-Null
        }
        Else
        {
            Set-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
                -Value $delimitedHostNames | Out-Null
        }

        Write-Host -Fore Green ("Successfully added host names ($HostNames) to" `
            + " BackConnectionHostNames.")
    }
}
