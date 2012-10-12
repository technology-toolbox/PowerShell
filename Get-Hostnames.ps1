<#
.SYNOPSIS
Gets the hostnames (and corresponding IP addresses) specified in the hosts file.

.DESCRIPTION
The hosts file is used to map hostnames to IP addresses.

.EXAMPLE
.\Get-HostNames.ps1

Hostname                                                    IpAddress
--------                                                    ---------
localhost                                                   127.0.0.1
fabrikam-local                                              127.0.0.1
www-local.fabrikam.com                                      127.0.0.1
#>

$ErrorActionPreference = "Stop"

function ParseHostsEntry(
    [string] $line)
{
    $hostsEntry = New-Object PSObject
    $hostsEntry | Add-Member NoteProperty -Name "IpAddress" -Value $null
    $hostsEntry | Add-Member NoteProperty -Name "Hostnames" -Value $null
    $hostsEntry | Add-Member NoteProperty -Name "Comment" -Value $null

    Write-Debug "Parsing hosts entry: $line"

    If ($line.Contains("#") -eq $true)
    {
        If ($line -eq "#")
        {
            $hostsEntry.Comment = [string]::Empty
        }
        Else
        {
            $hostsEntry.Comment = $line.Substring($line.IndexOf("#") + 1)
        }

        $line = $line.Substring(0, $line.IndexOf("#"))
    }

    $line = $line.Trim()

    If ($line.Length -gt 0)
    {
        $hostsEntry.IpAddress = ($line -Split "\s+")[0]

        Write-Debug "Parsed address: $($hostsEntry.IpAddress)"

        [string[]] $parsedHostnames = $line.Substring(
            $hostsEntry.IpAddress.Length + 1).Trim() -Split "\s+"

        Write-Debug ("Parsed hostnames ($($parsedHostnames.Length)):" `
            + " $parsedHostnames")

        $hostsEntry.Hostnames = New-Object System.Collections.ArrayList

        $parsedHostnames | foreach {
            $hostsEntry.Hostnames.Add($_) | Out-Null
        }
    }

    return $hostsEntry
}

function Main()
{
    [string] $hostsFile = $env:WINDIR + "\System32\drivers\etc\hosts"

    [string[]] $hostsContent = Get-Content $hostsFile

    $hostsContent | foreach {
        $hostsEntry = ParseHostsEntry $_

        Write-Debug "Hosts entry: $hostsEntry"

        If ($hostsEntry.Hostnames -eq $null)
        {
            return
        }

        $hostsEntry.Hostnames | foreach {
            $properties = @{
                Hostname = $_
                IpAddress = $hostsEntry.IpAddress
            }

            New-Object PSObject -Property $properties
        }
    }
}

Main
