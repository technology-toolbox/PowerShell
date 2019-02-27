<#
.SYNOPSIS
Sets the TCP/IP configuration parameter that controls the number of times the
computer sends a gratuitous ARP for its own IP address(es) while initializing.

.DESCRIPTION
When starting virtual machines joined to a domain, an error may be reported in
the System event log stating the "computer was not able to set up a secure
session with a domain controller in domain..." (Source: NETLOGON, Event ID:
5719). Setting the ArpRetryCount parameter to 0 prevents this error from
occurring.

.PARAMETER ArpRetryCount
The number of times the computer sends a gratuitous ARP for its own IP
address(es) while initializing.

.LINK
http://technet.microsoft.com/en-us/library/cc739819.aspx

.EXAMPLE
.\Set-ArpRetryCount.ps1 0

Description
-----------
Sets the value of the ArpRetryCount parameter to 0 (for example, to prevent
NETLOGON 5719 errors when starting a virtual machine joined to a domain).

.NOTES
This script must be run with administrator privileges.
#>
function Set-ArpRetryCount {
    param(
        [parameter(Mandatory = $true)]
        [int] $ArpRetryCount)

    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
    }

    Process {
        [string] $tcpIpParametersPath =
            "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

        $tcpIpParametersKey = Get-Item -Path $tcpIpParametersPath

        $currentArpRetryCount = $tcpIpParametersKey.GetValue("ArpRetryCount")

        If ($currentArpRetryCount -eq $null) {
            New-ItemProperty -Path $tcpIpParametersPath -Name ArpRetryCount `
                -PropertyType DWord -Value $ArpRetryCount | Out-Null
        }
        ElseIf ($currentArpRetryCount -eq $ArpRetryCount) {
            Write-Verbose ("ArpRetryCount is already set to {0}." -f $ArpRetryCount)
            return
        }
        Else {
            Set-ItemProperty -Path $tcpIpParametersPath -Name ArpRetryCount `
                -Value $ArpRetryCount | Out-Null
        }

        Write-Host -Fore Green ("Successfully set ArpRetryCount to {0}." `
                -f $ArpRetryCount)
    }
}