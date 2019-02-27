<#
.SYNOPSIS
Gets the TCP/IP configuration parameter that controls the number of times the
computer sends a gratuitous ARP for its own IP address(es) while initializing.

.DESCRIPTION
When starting virtual machines joined to a domain, an error may be reported in
the System event log stating the "computer was not able to set up a secure
session with a domain controller in domain..." (Source: NETLOGON, Event ID:
5719). Setting the ArpRetryCount parameter to 0 prevents this error from
occurring.

.EXAMPLE
.\Get-ArpRetryCount.ps1
0

Description
-----------
In this example, the ArpRetryCount parameter has previously been set to 0 (to prevent
NETLOGON 5719 errors).
#>
function Get-ArpRetryCount {
    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
    }

    Process {
        [string] $tcpIpParametersPath =
            "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

        Get-ItemProperty -Path $tcpIpParametersPath -Name ArpRetryCount |
            ForEach-Object { $_.ArpRetryCount }
    }
}
