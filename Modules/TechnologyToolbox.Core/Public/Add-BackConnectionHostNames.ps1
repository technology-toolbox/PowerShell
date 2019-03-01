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
function Add-BackConnectionHostNames {
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $HostNames)

    begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

        [bool] $isInputFromPipeline =
        ($PSBoundParameters.ContainsKey("HostNames") -eq $false)

        [int] $hostNamesAdded = 0

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

            $hostNameList | foreach {
                If ([string]::Compare($_, $hostName, $true) -eq 0) {
                    Write-Verbose ("The host name ($hostName) is already" `
                            + " specified in the BackConnectionHostNames list.")

                    $isHostNameInList = $true
                    return
                }
            }

            If ($isHostNameInList -eq $false) {
                Write-Verbose ("Adding host name ($hostName) to" `
                        + " BackConnectionHostNames list...")

                $hostNameList.Add($hostName) | Out-Null

                $hostNamesAdded++
            }
        }
    }

    end {
        If ($hostNamesAdded -eq 0) {
            Write-Verbose ("No changes to the BackConnectionHostNames registry" `
                    + " value are necessary.")

            return
        }

        SetBackConnectionHostNamesRegistryValue $hostNameList

        Write-Verbose ("Successfully added $hostNamesAdded host name(s) to" `
                + " the BackConnectionHostNames registry value.")
    }
}