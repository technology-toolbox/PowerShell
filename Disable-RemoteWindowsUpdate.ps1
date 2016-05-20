<#
.SYNOPSIS
Disables firewall rules for remote Windows Update.

.DESCRIPTION
Auditing and installing updates using POSHPAIG (http://poshpaig.codeplex.com/)
requires specific ports and protocols to be enabled through Windows Firewall
(which are enabled by running Enable-RemoteWindowsUpdate.ps1). This script
disables all firewall rules in the "Remote Windows Update" group.

.EXAMPLE
.\Disable-RemoteWindowsUpdate.ps1

.NOTES
This script must be run with administrator privileges.
#>

[CmdletBinding()]
Param()

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
}

Process
{
    Write-Verbose 'Disabling firewall rules for remote Windows Update...'

    Disable-NetFirewallRule -Group 'Remote Windows Update'
}