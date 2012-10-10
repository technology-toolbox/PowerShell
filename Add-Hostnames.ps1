<#
.SYNOPSIS
Adds one or more hostnames to the hosts file.

.DESCRIPTION
The hosts file is used to map hostnames to IP addresses.

.PARAMETER IPAddress 
The IP address to map the hostname(s) to.

.PARAMETER Hostnames 
One or more hostnames to map to the specified IP address.

.PARAMETER Comment 
Optional comment that is written above the new hosts entry.

.EXAMPLE
Add-Hostnames 127.0.0.1 foobar

Description
-----------
Adds the following line to the hosts file (assuming "foobar" does not already
exist in the hosts file):

127.0.0.1    foobar

A warning is displayed if "foobar" already exists in the hosts file and is
mapped to the specified IP address. An error occurs if "foobar" is already
mapped to a different IP address.

.EXAMPLE
Add-Hostnames 127.0.0.1 "foo bar" "This is a comment"

Description
-----------
Adds the following lines to the hosts file (assuming "foo" and "bar" do not
already exist in the hosts file):

# This is a comment
127.0.0.1    foo bar

A warning is displayed if either "foo" or "bar" already exists in the hosts
file and is mapped to the specified IP address. An error occurs if "foo" or
"bar" is already mapped to a different IP address.

.NOTES
This script must be run with administrator privileges.
#>
param(
    [parameter(Mandatory=$true)]
    [string] $IPAddress,
    [parameter(Mandatory=$true)]
    [string] $Hostnames,
    [string] $Comment
)

[bool] $addHostsEntry = $true

[string[]] $splitHostnames = $Hostnames -Split "\s+"

If ($splitHostnames.Length -eq 1)
{
    Write-Host "Adding hostname ($splitHostnames) to hosts file..."
}
Else
{
    Write-Host ("Adding $splitHostnames.Length hostnames ($splitHostnames) to" `
        + " hosts file...")
}
        
[string] $hostsFile = $env:WINDIR + "\System32\drivers\etc\hosts"

[string[]] $hostsEntries = Get-Content $hostsFile

$hostsEntries | foreach {
    [string] $line = $_.Trim()
    
    If ($line.Contains("#") -eq $true)
    {
        $line = $line.Substring(0, $line.IndexOf("#"))
    }
    
    If ($line.Length -gt 0)
    {
        Write-Debug "Line: $line"
        
        [string] $parsedAddress = ($line -Split "\s+")[0]
        
        Write-Debug "Parsed address: $parsedAddress"
        
        [string[]] $parsedHostnames = $line.Substring(
            $parsedAddress.Length + 1).Trim() -Split "\s+"
            
        Write-Debug "Parsed hostnames ($($parsedHostnames.Length)): $parsedHostnames"
        
        $parsedHostnames | foreach {
            [string] $parsedHostname = $_
            
            $newHostnames | foreach {            
                Write-Debug ("Comparing new hostname ($_) to existing hostname" `
                    + " ($parsedHostname)...")
        
                If ([string]::Compare($_, $parsedHostname, $true) -eq 0)
                {                         
                    If ($IPAddress -ne $parsedAddress)
                    {
                        Throw "The hosts file already contains the" `
                            + " specified hostname ($parsedHostname) and it is" `
                            + " mapped to a different address" `
                            + " ($parsedAddress)."
                    }
                    Else
                    {
                        Write-Warning ("The entry cannot be added because the" `
                            + " hosts file already contains the specified" `
                            + " hostname ($parsedAddress $parsedHostname).")
                            
                        Exit
                    }
                }
            }        
        }
    }
}

If ($addHostsEntry -eq $true)
{
    Add-Content -Path $hostsFile -Value "`n"

    If ([string]::IsNullOrEmpty($Comment) -eq $false)
    {
        Add-Content -Path $hostsFile -Value "# $Comment"
    }

    [string] $hostsEntry = "$IPAddress`t$Hostnames"
    
    Add-Content -Path $hostsFile -Value $hostsEntry
    
    Write-Host -Fore Green "Successfully added hosts entry ($hostsEntry)."
}