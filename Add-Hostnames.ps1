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
.\Add-Hostnames.ps1 127.0.0.1 foobar

Description
-----------
Adds the following line to the hosts file (assuming "foobar" does not already
exist in the hosts file):

127.0.0.1    foobar

A warning is displayed if "foobar" already exists in the hosts file and is
mapped to the specified IP address. An error occurs if "foobar" is already
mapped to a different IP address.

.EXAMPLE
.\Add-Hostnames.ps1 127.0.0.1 foo, bar "This is a comment"

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
    [string[]] $Hostnames,
    [string] $Comment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function AddHostsEntry(
    [string] $hostsFile = $(Throw "Value cannot be null: hostsFile"),
    [string] $ipAddress = $(Throw "Value cannot be null: ipAddress"),
    [string] $hostnames = $(Throw "Value cannot be null: hostnames"),
    [string] $comment)
{
    # Ensure file ends with newline
    Add-Content -Path $hostsFile -Value ""

    If ([string]::IsNullOrEmpty($comment) -eq $false)
    {
        Add-Content -Path $hostsFile -Value "# $comment"
    }

    [string] $hostsEntry = "$ipAddress`t$hostnames"

    Add-Content -Path $hostsFile -Value $hostsEntry

    Write-Host -Fore Green "Successfully added hosts entry ($hostsEntry)."
}

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

function Main(
    [string] $ipAddress = $(Throw "Value cannot be null: ipAddress"),
    [string[]] $hostnames = $(Throw "Value cannot be null: hostnames"),
    [string] $comment)
{
    If ($hostnames.Length -eq 1)
    {
        Write-Host "Adding hostname ($hostnames) to hosts file..."
    }
    Else
    {
        Write-Host ("Adding $($hostnames.Length) hostnames ($hostnames) to" `
            + " hosts file...")
    }

    [string] $hostsFile = $env:WINDIR + "\System32\drivers\etc\hosts"

    [string[]] $hostsContent = Get-Content $hostsFile

    $hostsContent | foreach {
        $hostsEntry = ParseHostsEntry $_

        Write-Debug "Hosts entry: $hostsEntry"

        If ($hostsEntry.Hostnames -eq $null)
        {
            return
        }

        $hostsEntry.Hostnames | foreach {
            [string] $parsedHostname = $_

            $hostnames | foreach {
                Write-Debug ("Comparing new hostname ($_) to" `
                    + " existing hostname ($parsedHostname)...")

                If ([string]::Compare($_, $parsedHostname, $true) -eq 0)
                {
                    If ($ipAddress -ne $hostsEntry.IpAddress)
                    {
                        Throw "The hosts file already contains the" `
                            + " specified hostname ($parsedHostname) and it is" `
                            + " mapped to a different address" `
                            + " ($($hostsEntry.IpAddress))."
                    }
                    Else
                    {
                        Write-Warning ("Hostnames cannot be added because the" `
                            + " hosts file already contains the specified" `
                            + " hostname ($($hostsEntry.IpAddress) $parsedHostname).")

                        Exit
                    }
                }
            }
        }
    }

    AddHostsEntry $hostsFile $ipAddress $hostnames $comment
}

Main $IPAddress $Hostnames $Comment
