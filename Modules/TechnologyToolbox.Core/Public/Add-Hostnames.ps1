<#
.SYNOPSIS
Adds one or more hostnames to the hosts file.

.DESCRIPTION
The hosts file is used to map hostnames to IP addresses.

.PARAMETER IPAddress
The IP address to map the hostname(s) to.

.PARAMETER Hostnames
One or more hostnames to map to the specified IP address.

.PARAMETER Comment
Optional comment that is written above the new hosts entry.

.EXAMPLE
.\Add-Hostnames.ps1 127.0.0.1 foobar

Description
-----------
Adds the following line to the hosts file (assuming "foobar" does not already
exist in the hosts file):

127.0.0.1    foobar

A warning is displayed if "foobar" already exists in the hosts file and is
mapped to the specified IP address. An error occurs if "foobar" is already
mapped to a different IP address.

.EXAMPLE
.\Add-Hostnames.ps1 127.0.0.1 foo, bar "This is a comment"

Description
-----------
Adds the following lines to the hosts file (assuming "foo" and "bar" do not
already exist in the hosts file):

# This is a comment
127.0.0.1    foo bar

A warning is displayed if either "foo" or "bar" already exists in the hosts
file and is mapped to the specified IP address. An error occurs if "foo" or
"bar" is already mapped to a different IP address.

.NOTES
This script must be run with administrator privileges.
#>
function Add-Hostnames {
    param(
        [parameter(Mandatory = $true)]
        [string] $IPAddress,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Hostnames,
        [string] $Comment
    )

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

        [bool] $isInputFromPipeline =
        ($PSBoundParameters.ContainsKey("Hostnames") -eq $false)

        [int] $pendingUpdates = 0

        [Collections.ArrayList] $hostsEntries = ParseHostsFile
    }

    process {
        If ($isInputFromPipeline -eq $true) {
            $items = $_
        }
        Else {
            $items = $Hostnames
        }

        $newHostsEntry = CreateHostsEntryObject $IpAddress
        $hostsEntries.Add($newHostsEntry) | Out-Null

        $items | foreach {
            [string] $hostname = $_

            [bool] $isHostnameInHostsEntries = $false

            for ([int] $i = 0; $i -lt $hostsEntries.Count; $i++) {
                $hostsEntry = $hostsEntries[$i]

                Write-Debug "Hosts entry: $hostsEntry"

                If ($hostsEntry.Hostnames.Count -eq 0) {
                    continue
                }

                for ([int] $j = 0; $j -lt $hostsEntry.Hostnames.Count; $j++) {
                    [string] $parsedHostname = $hostsEntry.Hostnames[$j]

                    Write-Debug ("Comparing specified hostname" `
                            + " ($hostname) to existing hostname" `
                            + " ($parsedHostname)...")

                    If ([string]::Compare($hostname, $parsedHostname, $true) -eq 0) {
                        $isHostnameInHostsEntries = $true

                        If ($ipAddress -ne $hostsEntry.IpAddress) {
                            Throw "The hosts file already contains the" `
                                + " specified hostname ($parsedHostname) and it is" `
                                + " mapped to a different address" `
                                + " ($($hostsEntry.IpAddress))."
                        }

                        Write-Verbose ("The hosts file already contains the" `
                                + " specified hostname ($($hostsEntry.IpAddress) $parsedHostname).")
                    }
                }
            }

            If ($isHostnameInHostsEntries -eq $false) {
                Write-Debug ("Adding hostname ($hostname) to hosts entry...")

                $newHostsEntry.Hostnames.Add($hostname) | Out-Null
                $pendingUpdates++
            }
        }
    }

    end {
        If ($pendingUpdates -eq 0) {
            Write-Verbose "No changes to the hosts file are necessary."

            return
        }

        Write-Verbose ("There are $pendingUpdates pending update(s) to the hosts" `
                + " file.")

        UpdateHostsFile $hostsEntries
    }
}