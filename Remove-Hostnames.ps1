<#
.SYNOPSIS
Removes one or more hostnames from the hosts file.

.DESCRIPTION
The hosts file is used to map hostnames to IP addresses.

.PARAMETER Hostnames 
One or more hostnames to remove from the hosts file.

.EXAMPLE
Remove-Hostnames foobar

Description
-----------
Assume the following line was previously added to the hosts file:

127.0.0.1    foobar

After running "Remove-Hostnames foobar" the hosts file no longer contains this
line.

.EXAMPLE
Remove-Hostnames foo

Description
-----------
Assume the following line was previously added to the hosts file:

127.0.0.1    foobar foo bar

After running "Remove-Hostnames foo" the line in the hosts file is updated to
remove the specified hostname ("foo"):

127.0.0.1    foobar bar


.NOTES
This script must be run with administrator privileges.
#>
param(
    [parameter(Mandatory=$true)]
    [string] $Hostnames
)

function ParseHostsEntry(
    [string] $line)
{
    $hostsEntry = New-Object PSObject    
    $hostsEntry | Add-Member NoteProperty -Name "IpAddress" -Value $null
    $hostsEntry | Add-Member NoteProperty -Name "Hostnames" -Value $null        
    $hostsEntry | Add-Member NoteProperty -Name "Comment" -Value $null

    Write-Debug "Parsing hosts entry: $line"
    
    If ($line.Contains("#") -eq $true)
    {
        If ($line -eq "#")
        {
            $hostsEntry.Comment = [string]::Empty
        }
        Else
        {
            $hostsEntry.Comment = $line.Substring($line.IndexOf("#") + 1)
        }
        
        $line = $line.Substring(0, $line.IndexOf("#"))
    }
    
    $line = $line.Trim()

    If ($line.Length -gt 0)
    {        
        $hostsEntry.IpAddress = ($line -Split "\s+")[0]
        
        Write-Debug "Parsed address: $($hostsEntry.IpAddress)"
        
        [string[]] $parsedHostnames = $line.Substring(
            $hostsEntry.IpAddress.Length + 1).Trim() -Split "\s+"
            
        Write-Debug ("Parsed hostnames ($($parsedHostnames.Length)):" `
            + " $parsedHostnames")

        $hostsEntry.Hostnames = New-Object System.Collections.ArrayList
        
        $parsedHostnames | foreach {
            $hostsEntry.Hostnames.Add($_) | Out-Null
        }
    }
    
    return $hostsEntry
}

function UpdateHostsFile(
    [string] $hostsFile = $(Throw "Value cannot be null: hostsFile"),
    $hostsEntries = $(Throw "Value cannot be null: hostsEntries"))
{
    $buffer = New-Object System.Text.StringBuilder
        
    $hostsEntries | foreach {

        If ([string]::IsNullOrEmpty($_.IpAddress) -eq $false)
        {
            $buffer.Append($_.IpAddress) | Out-Null
            $buffer.Append("`t") | Out-Null
        }
        
        If ($_.Hostnames -ne $null)
        {
            [bool] $firstHostname = $true
            
            $_.Hostnames | foreach {                
                If ($firstHostname -eq $false)
                {
                    $buffer.Append(" ") | Out-Null
                }
                Else
                {                
                    $firstHostname = $false
                }
                
                $buffer.Append($_) | Out-Null
            }
        }
        
        If ($_.Comment -ne $null)
        {
            If ([string]::IsNullOrEmpty($_.IpAddress) -eq $false)
            {
                $buffer.Append(" ") | Out-Null
            }
        
            $buffer.Append("#") | Out-Null
            $buffer.Append($_.Comment) | Out-Null
        }

        $buffer.Append([System.Environment]::NewLine) | Out-Null
    }
    
    [string] $hostsContent = $buffer.ToString()
    
    $hostsContent = $hostsContent.Trim()
    
    Set-Content -Path $hostsFile -Value $hostsContent -Force -Encoding ASCII

    Write-Host -Fore Green "Successfully updated hosts file."
}

function Main(
    [string] $hostnames = $(Throw "Value cannot be null: hostnames"))
{
    [int] $pendingUpdates = 0
    
    [string[]] $splitHostnames = $hostnames -Split "\s+"

    If ($splitHostnames.Length -eq 1)
    {
        Write-Host "Removing hostname ($splitHostnames) from hosts file..."
    }
    Else
    {
        Write-Host ("Removing $splitHostnames.Length hostnames" `
            + " ($splitHostnames) from hosts file...")
    }
            
    [string] $hostsFile = $env:WINDIR + "\System32\drivers\etc\hosts"

    [string[]] $hostsContent = Get-Content $hostsFile

    $hostsEntries = New-Object System.Collections.ArrayList
    
    [string[]] $hostsContent = Get-Content $hostsFile

    $hostsContent | foreach {
        $hostsEntry = ParseHostsEntry $_
        
        $hostsEntries.Add($hostsEntry) | Out-Null
    }
        
    for ([int] $i = 0; $i -lt $hostsEntries.Count; $i++)
    {
        $hostsEntry = $hostsEntries[$i]        
        
        Write-Debug "Hosts entry: $hostsEntry"
        
        If ($hostsEntry.Hostnames -eq $null)
        {
            continue
        }
        
        for ([int] $j = 0; $j -lt $hostsEntry.Hostnames.Count; $j++)
        {
            [string] $parsedHostname = $hostsEntry.Hostnames[$j]
            
            $splitHostnames | foreach {
                Write-Debug ("Comparing specified hostname" `
                    + " ($_) to existing hostname" `
                    + " ($parsedHostname)...")
        
                If ([string]::Compare($_, $parsedHostname, $true) -eq 0)
                {
                    Write-Debug "Removing hostname ($_) from host entry ($hostEntry)..."

                    $hostsEntry.Hostnames.RemoveAt($j)
                    $j--
                    
                    $pendingUpdates++
                }
            }
        }
            
        If ($hostsEntry.Hostnames.Count -eq 0)
        {
            Write-Debug ("Removing host entry (because it no longer specifies" `
                + " any hostnames)...")
                    
            $hostsEntries.RemoveAt($i)
            $i--
        }
    }
    
    If ($pendingUpdates -gt 0)
    {
        Write-Host ("There are $pendingUpdates pending update(s) to the hosts" `
            + " file.")
        
        UpdateHostsFile $hostsFile $hostsEntries
    }
    Else
    {
        Write-Host "No changes to the hosts file are necessary."
    }
}

Main $Hostnames