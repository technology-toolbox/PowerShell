<#
.SYNOPSIS
Removes one or more hostnames from the hosts file.

.DESCRIPTION
The hosts file is used to map hostnames to IP addresses.

.PARAMETER Hostnames
One or more hostnames to remove from the hosts file.

.EXAMPLE
.\Remove-Hostnames.ps1 foobar

Description
-----------
Assume the following line was previously added to the hosts file:

127.0.0.1    foobar

After running "Remove-Hostnames.ps1 foobar" the hosts file no longer contains this
line.

.EXAMPLE
.\Remove-Hostnames.ps1 foo

Description
-----------
Assume the following line was previously added to the hosts file:

127.0.0.1    foobar foo bar

After running "Remove-Hostnames.ps1 foo" the line in the hosts file is updated
to remove the specified hostname ("foo"):

127.0.0.1    foobar bar

.EXAMPLE
.\Remove-Hostnames.ps1 foo, bar

Description
-----------
Assume the following line was previously added to the hosts file:

127.0.0.1    foobar foo bar

After running "Remove-Hostnames.ps1 foo, bar" the line in the hosts file is updated to
remove the specified hostnames ("foo" and "bar"):

127.0.0.1    foobar

.NOTES
This script must be run with administrator privileges.
#>
function Remove-Hostnames {
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Hostnames
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

        $items | foreach {
            [string] $hostname = $_

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
                        Write-Debug "Removing hostname ($hostname) from host entry ($hostsEntry)..."

                        $hostsEntry.Hostnames.RemoveAt($j)
                        $j--

                        $pendingUpdates++
                    }
                }

                If ($hostsEntry.Hostnames.Count -eq 0) {
                    Write-Debug ("Removing host entry (because it no longer specifies" `
                            + " any hostnames)...")

                    $hostsEntries.RemoveAt($i)
                    $i--
                }
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