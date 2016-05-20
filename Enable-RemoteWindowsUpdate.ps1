<#
.SYNOPSIS
Enables firewall rules for remote Windows Update.

.DESCRIPTION
Auditing and installing updates using POSHPAIG (http://poshpaig.codeplex.com/)
requires specific ports and protocols to be enabled through Windows Firewall.
This script creates the necessary firewall rules, as necessary, and enables
all firewall rules in the "Remote Windows Update" group.

.EXAMPLE
.\Enable-RemoteWindowsUpdate.ps1

.NOTES
This script must be run with administrator privileges.
#>
[CmdletBinding()]
Param()

Begin
{
    $ErrorActionPreference = "Stop"

    Function DoesFirewallRuleExist(
        [string] $ruleName)
    {
        $rule = Get-NetFirewallRule `
            -Name $ruleName `
            -ErrorAction SilentlyContinue

        return ($rule -ne $null)
    }

    Function EnsureFirewallRulesForRemoteWindowsUpdate()
    {
        # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

        $ruleDescription = 'Allows remote auditing and installation of Windows' `
            + ' updates via POSHPAIG (http://poshpaig.codeplex.com/)'

        $ruleName = 'RWU-DCOM-In'
        $ruleDisplayName = 'Remote Windows Update (DCOM-In)'

        If ((DoesFirewallRuleExist $ruleName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            New-NetFirewallRule `
                -Name $ruleName `
                -DisplayName $ruleDisplayName `
                -Description $ruleDescription `
                -Group 'Remote Windows Update' `
                -Direction Inbound `
                -Protocol TCP `
                -LocalPort 135 `
                -Profile Domain `
                -Action Allow | Out-Null
        }

        $ruleName = 'RWU-Dynamic-RPC-In'
        $ruleDisplayName = 'Remote Windows Update (Dynamic RPC)'
        
        If ((DoesFirewallRuleExist $ruleName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            New-NetFirewallRule `
                -Name $ruleName `
                -DisplayName $ruleDisplayName `
                -Description $ruleDescription `
                -Group 'Remote Windows Update' `
                -Program '%windir%\system32\dllhost.exe' `
                -Direction Inbound `
                -Protocol TCP `
                -LocalPort RPC `
                -Profile Domain `
                -Action Allow | Out-Null
        }
        
        $ruleName = 'RWU-ICMP4-ERQ-In'
        $ruleDisplayName = 'Remote Windows Update (Echo Request - ICMPv4-In)'
        
        If ((DoesFirewallRuleExist $ruleName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            New-NetFirewallRule `
                -Name $ruleName `
                -DisplayName $ruleDisplayName `
                -Description $ruleDescription `
                -Group 'Remote Windows Update' `
                -Direction Inbound `
                -Protocol ICMPv4 `
                -IcmpType 8 `
                -Profile Domain `
                -Action Allow | Out-Null
        }
        
        $ruleName = 'RWU-ICMP6-ERQ-In'
        $ruleDisplayName = 'Remote Windows Update (Echo Request - ICMPv6-In)'
        
        If ((DoesFirewallRuleExist $ruleName) -eq $false)
        {        
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            New-NetFirewallRule `
                -Name $ruleName `
                -DisplayName $ruleDisplayName `
                -Description $ruleDescription `
                -Group 'Remote Windows Update' `
                -Direction Inbound `
                -Protocol ICMPv6 `
                -IcmpType 128 `
                -Profile Domain `
                -Action Allow | Out-Null
        }
        
        $ruleName = 'RWU-SMB-In'
        $ruleDisplayName = 'Remote Windows Update (SMB-In)'
        
        If ((DoesFirewallRuleExist $ruleName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            New-NetFirewallRule `
                -Name $ruleName `
                -DisplayName $ruleDisplayName `
                -Description $ruleDescription `
                -Group 'Remote Windows Update' `
                -Direction Inbound `
                -Protocol TCP `
                -LocalPort 445 `
                -Profile Domain `
                -Action Allow | Out-Null
        }
        
        $ruleName = 'RWU-WMI-In'
        $ruleDisplayName = 'Remote Windows Update (WMI-In)'
        
        If ((DoesFirewallRuleExist $ruleName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            New-NetFirewallRule `
                -Name $ruleName `
                -DisplayName $ruleDisplayName `
                -Description $ruleDescription `
                -Group 'Remote Windows Update' `
                -Program '%SystemRoot%\system32\svchost.exe' `
                -Service Winmgmt `
                -Direction Inbound `
                -Profile Domain `
                -Action Allow | Out-Null
        }
    }
}

Process
{
    EnsureFirewallRulesForRemoteWindowsUpdate

    Write-Verbose 'Enabling firewall rules for remote Windows Update...'

    Enable-NetFirewallRule -Group 'Remote Windows Update'
}