<#
.SYNOPSIS
Removes one or more host names from the BackConnectionHostNames registry value.

.DESCRIPTION
The BackConnectionHostNames registry value is used to bypass the loopback
security check for specific host names.

.LINK
http://support.microsoft.com/kb/896861

.EXAMPLE
.\Remove-BackConnectionHostNames.ps1 fabrikam-local, www-local.fabrikam.com
#>
function Remove-BackConnectionHostNames {
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $HostNames)

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

        [bool] $isInputFromPipeline =
        ($PSBoundParameters.ContainsKey("HostNames") -eq $false)

        [int] $hostNamesRemoved = 0

        [Collections.ArrayList] $hostNameList = GetBackConnectionHostNameList
    }

    process {
        If ($isInputFromPipeline -eq $true) {
            $items = $_
        }
        Else {
            $items = $HostNames
        }

        $items | foreach {
            [string] $hostName = $_

            [bool] $isHostNameInList = $false

            for ([int] $i = 0; $i -lt $hostNameList.Count; $i++) {
                If ([string]::Compare($hostNameList[$i], $hostName, $true) -eq 0) {
                    Write-Verbose ("Removing host name ($hostName) from" `
                            + " BackConnectionHostNames list...")

                    $hostNameList.RemoveAt($i)
                    $i--

                    $hostNamesRemoved++

                    $isHostNameInList = $true
                }
            }

            If ($isHostNameInList -eq $false) {
                Write-Verbose ("The host name ($hostName) is not" `
                        + " specified in the BackConnectionHostNames list.")

            }
        }
    }

    end {
        If ($hostNamesRemoved -eq 0) {
            Write-Verbose ("No changes to the BackConnectionHostNames registry" `
                    + " value are necessary.")

            return
        }

        SetBackConnectionHostNamesRegistryValue $hostNameList

        Write-Verbose ("Successfully removed $hostNamesRemoved host name(s)" `
                + " from the BackConnectionHostNames registry value.")
    }
}