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
function Get-Hostnames {
    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

        [Collections.ArrayList] $hostsEntries = ParseHostsFile
    }

    process {
        $hostsEntries | foreach {
            $hostsEntry = $_

            $hostsEntry.Hostnames | foreach {
                $properties = @{
                    Hostname  = $_
                    IpAddress = $hostsEntry.IpAddress
                }

                New-Object PSObject -Property $properties
            }
        }
    }
}
