<#
.SYNOPSIS
Creates a cluster name object (CNO) or virtual computer object (VCO) in Active
Directory and grants Full Control to the specified user, group, or computer
"delegate."

.LINK
https://technet.microsoft.com/en-us/library/dn466519(v=ws.11).aspx

.EXAMPLE
.\New-ClusterObject.ps1 -Name SQL01-FC -Delegate "SQL Server Admins"

Creates a cluster name object for a SQL Server failover cluster ("SQL01-FC") in
the  default "Computers" organizational unit and grants permissions to create
the cluster to any member of the SQL Server administrators group
("SQL Server Admins").

.EXAMPLE
.\New-ClusterObject.ps1 -Name SQL01 -Delegate "SQL01-FC$" -Path "OU=SQL Servers,OU=Servers,OU=Resources,OU=IT,DC=corp,DC=technologytoolbox,DC=com"

Creates a virtual computer object for a SQL Server availability group listener
("SQL01") in the specified organizational unit and grants permissions to create
the availability group listener to the failover cluster computer account
("SQL01-FC").
#>
Param (
    [Parameter(Mandatory = $true)]
    [string] $Name,
    [Parameter(Mandatory = $true)]
    [string] $Delegate,
    [string] $Path,
    [string] $Description = "Failover cluster virtual network name",
    [switch] $PassThru)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
}

Process
{
    If ([string]::IsNullOrWhiteSpace($Path) -eq $true)
    {
        $domain = Get-ADDomain

        $Path = $domain.ComputersContainer
    }

    $user = Get-ADUser -Filter {SamAccountName -eq $Delegate}
    $group = Get-ADGroup -Filter {SamAccountName -eq $Delegate}
    $computer = $null

    If ($Delegate.EndsWith('$') -eq $true)
    {
        $computer = Get-ADComputer -Filter {SamAccountName -eq $Delegate}
    }

    If (($user -eq $null) `
        -and ($group -eq $null) `
        -and ($computer -eq $null))
    {
        Throw "Unable to find user, group, or computer ($Delegate)."
    }

    Write-Verbose "Creating computer object ($Name)..."

    $clusterObject = New-ADComputer `
        -Name $Name `
        -Description $Description `
        -Path $Path `
        -Enabled:$false `
        -PassThru

    Write-Verbose ("Protecting computer object ($Name) from accidental" `
        + " deletion...")

    Set-ADObject `
        -Identity $clusterObject `
        -ProtectedFromAccidentalDeletion $true

    Write-Verbose ("Granting delegate ($Delegate) permissions on computer" `
        + " object ($Name)...")

    [string] $clusterObjectDN = $clusterObject.DistinguishedName

    Write-Verbose ("Waiting a few seconds to avoid occasional issue where" `
        + " the cluster object just created is not found when getting the" `
        + " ACL using the distinguished name...")

    Start-Sleep -Seconds 5

    $acl = Get-Acl -Path "AD:\$clusterObjectDN"

    $delegateAccount = New-Object System.Security.Principal.NTAccount($Delegate)

    $accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
        $delegateAccount,
        "GenericAll",
        "Allow")

    $acl.AddAccessRule($accessRule)

    Set-Acl -Path "AD:\$clusterObjectDN" -AclObject $acl

    If ($PassThru -eq $true)
    {
        return Get-ADComputer -Identity $Name
    }
}
