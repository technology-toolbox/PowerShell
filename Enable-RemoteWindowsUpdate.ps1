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
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function AreFilewallPowerShellCmdletsAvailable()
    {
        If ([Environment]::OSVersion.Version -ge (New-Object 'Version' 6,2))
        {
            return $true
        }
        Else
        {
            return $false
        }
    }

    Function DoesFirewallRuleExist(
        [string] $ruleDisplayName)
    {
        If (AreFilewallPowerShellCmdletsAvailable -eq $true)
        {
            $rule = Get-NetFirewallRule `
                -DisplayName $ruleName `
                -ErrorAction SilentlyContinue

            return ($rule -ne $null)
        }
        Else
        {
            netsh advfirewall firewall show rule name="$ruleDisplayName" |
                Out-Null
            
            return ($LASTEXITCODE -eq 0)
        }
    }

    Function EnsureFirewallRulesForRemoteWindowsUpdate(
	    [string] $groupName)
    {
        # Configure firewall rules for POSHPAIG (http://poshpaig.codeplex.com/)

        $ruleDescription = 'Allows remote auditing and installation of Windows' `
            + ' updates via POSHPAIG (http://poshpaig.codeplex.com/)'

        $ruleName = 'RWU-DCOM-In'
        $ruleDisplayName = 'Remote Windows Update (DCOM-In)'

        If ((DoesFirewallRuleExist $ruleDisplayName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            If (AreFilewallPowerShellCmdletsAvailable -eq $true)
            {
                New-NetFirewallRule `
                    -Name $ruleName `
                    -DisplayName $ruleDisplayName `
                    -Description $ruleDescription `
                    -Group $groupName `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 135 `
                    -Profile Domain `
                    -Action Allow | Out-Null
            }
            Else
            {
                netsh advfirewall firewall add rule `
                    name="$ruleDisplayName" `
                    description="$ruleDescription" `
                    dir=in `
                    protocol=TCP `
                    localport=135 `
                    profile=domain `
                    action=allow | Out-Null

                If ($LASTEXITCODE -ne 0)
                {
                    Throw "An error ocurred while creating the firewall rule."
                }

                SetGroupForFirewallRule $ruleDisplayName $groupName
            }
        }

        $ruleName = 'RWU-Dynamic-RPC-In'
        $ruleDisplayName = 'Remote Windows Update (Dynamic RPC)'
        
        If ((DoesFirewallRuleExist $ruleDisplayName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            If (AreFilewallPowerShellCmdletsAvailable -eq $true)
            {
                New-NetFirewallRule `
                    -Name $ruleName `
                    -DisplayName $ruleDisplayName `
                    -Description $ruleDescription `
                    -Group $groupName `
                    -Program '%windir%\system32\dllhost.exe' `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort RPC `
                    -Profile Domain `
                    -Action Allow | Out-Null
            }
            Else
            {
                netsh advfirewall firewall add rule `
                    name="$ruleDisplayName" `
                    description="$ruleDescription" `
                    program="%windir%\system32\dllhost.exe" `
                    dir=in `
                    protocol=TCP `
                    localport=RPC `
                    profile=domain `
                    action=allow | Out-Null

                If ($LASTEXITCODE -ne 0)
                {
                    Throw "An error ocurred while creating the firewall rule."
                }

                SetGroupForFirewallRule $ruleDisplayName $groupName
            }
        }
        
        $ruleName = 'RWU-ICMP4-ERQ-In'
        $ruleDisplayName = 'Remote Windows Update (Echo Request - ICMPv4-In)'
        
        If ((DoesFirewallRuleExist $ruleDisplayName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            If (AreFilewallPowerShellCmdletsAvailable -eq $true)
            {
                New-NetFirewallRule `
                    -Name $ruleName `
                    -DisplayName $ruleDisplayName `
                    -Description $ruleDescription `
                    -Group $groupName `
                    -Direction Inbound `
                    -Protocol ICMPv4 `
                    -IcmpType 8 `
                    -Profile Domain `
                    -Action Allow | Out-Null
            }
            Else
            {
                netsh advfirewall firewall add rule `
                    name="$ruleDisplayName" `
                    description="$ruleDescription" `
                    dir=in `
                    protocol="icmpv4:8,any" `
                    profile=domain `
                    action=allow | Out-Null

                If ($LASTEXITCODE -ne 0)
                {
                    Throw "An error ocurred while creating the firewall rule."
                }

                SetGroupForFirewallRule $ruleDisplayName $groupName
            }
        }
        
        $ruleName = 'RWU-ICMP6-ERQ-In'
        $ruleDisplayName = 'Remote Windows Update (Echo Request - ICMPv6-In)'
        
        If ((DoesFirewallRuleExist $ruleDisplayName) -eq $false)
        {        
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            If (AreFilewallPowerShellCmdletsAvailable -eq $true)
            {
                New-NetFirewallRule `
                    -Name $ruleName `
                    -DisplayName $ruleDisplayName `
                    -Description $ruleDescription `
                    -Group $groupName `
                    -Direction Inbound `
                    -Protocol ICMPv6 `
                    -IcmpType 128 `
                    -Profile Domain `
                    -Action Allow | Out-Null
            }
            Else
            {
                netsh advfirewall firewall add rule `
                    name="$ruleDisplayName" `
                    description="$ruleDescription" `
                    dir=in `
                    protocol="icmpv6:128,any" `
                    profile=domain `
                    action=allow | Out-Null

                If ($LASTEXITCODE -ne 0)
                {
                    Throw "An error ocurred while creating the firewall rule."
                }

                SetGroupForFirewallRule $ruleDisplayName $groupName
            }
        }
        
        $ruleName = 'RWU-SMB-In'
        $ruleDisplayName = 'Remote Windows Update (SMB-In)'
        
        If ((DoesFirewallRuleExist $ruleDisplayName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            If (AreFilewallPowerShellCmdletsAvailable -eq $true)
            {
                New-NetFirewallRule `
                    -Name $ruleName `
                    -DisplayName $ruleDisplayName `
                    -Description $ruleDescription `
                    -Group $groupName `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 445 `
                    -Profile Domain `
                    -Action Allow | Out-Null
            }
            Else
            {
                netsh advfirewall firewall add rule `
                    name="$ruleDisplayName" `
                    description="$ruleDescription" `
                    dir=in `
                    protocol=TCP `
                    localport=445 `
                    profile=domain `
                    action=allow | Out-Null

                If ($LASTEXITCODE -ne 0)
                {
                    Throw "An error ocurred while creating the firewall rule."
                }

                SetGroupForFirewallRule $ruleDisplayName $groupName
            }
        }
        
        $ruleName = 'RWU-WMI-In'
        $ruleDisplayName = 'Remote Windows Update (WMI-In)'
        
        If ((DoesFirewallRuleExist $ruleDisplayName) -eq $false)
        {
            Write-Verbose "Creating firewall rule ($ruleDisplayName)..."

            If (AreFilewallPowerShellCmdletsAvailable -eq $true)
            {
                New-NetFirewallRule `
                    -Name $ruleName `
                    -DisplayName $ruleDisplayName `
                    -Description $ruleDescription `
                    -Group $groupName `
                    -Program '%SystemRoot%\system32\svchost.exe' `
                    -Service Winmgmt `
                    -Direction Inbound `
                    -Profile Domain `
                    -Action Allow | Out-Null
            }
            Else
            {
                netsh advfirewall firewall add rule `
                    name="$ruleDisplayName" `
                    description="$ruleDescription" `
                    program="%SystemRoot%\system32\svchost.exe" `
                    service="Winmgmt" `
                    dir=in `
                    profile=domain `
                    action=allow | Out-Null

                If ($LASTEXITCODE -ne 0)
                {
                    Throw "An error ocurred while creating the firewall rule."
                }

                SetGroupForFirewallRule $ruleDisplayName $groupName
            }
        }
    }

    Function SetGroupForFirewallRule(
        [string] $ruleName,
        [string] $groupName)
    {
        Write-Verbose "Setting group ($groupName) on firewall rule ($ruleName)..."

        $firewallPolicy = New-Object -ComObject hnetcfg.fwpolicy2

        $firewallPolicy.rules |
            Where-Object { $_.name -eq $ruleName } |
            ForEach-Object { $_.grouping = $groupName }
    }
}

Process
{
    $groupName = 'Remote Windows Update'

    EnsureFirewallRulesForRemoteWindowsUpdate $groupName

    Write-Verbose 'Enabling firewall rules for remote Windows Update...'

    If (AreFilewallPowerShellCmdletsAvailable -eq $true)
    {
        Enable-NetFirewallRule -Group $groupName
    }
    Else
    {
        netsh advfirewall firewall set rule `
            group="$groupName" new enable=yes | Out-Null

        If ($LASTEXITCODE -ne 0)
        {
            Throw "An error ocurred while enabling the firewall rules."
        }
    }
}
