<#
.SYNOPSIS
Gets the list of folders specified in the Path environment variable.

.PARAMETER EnvironmentVariableTarget
Specifies the "scope" to use when querying the Path environment variable
("Process", "Machine", or "User"). Defaults to "Process" if the parameter is
not specified.

.EXAMPLE
.\Get-PathFolders.ps1

Folder
------
C:\Windows\system32\WindowsPowerShell\v1.0\
C:\Windows\system32
C:\Windows
C:\Windows\System32\Wbem
...

.EXAMPLE
.\Get-PathFolders.ps1 "User"

Folder
------
C:\NotBackedUp\Public\Toolbox
#>
param(
    [string] $EnvironmentVariableTarget = "Process")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[string[]] $path = [Environment]::GetEnvironmentVariable(
    "Path",
    $EnvironmentVariableTarget) -Split ";"

If ($path -ne $null)
{
    $path | foreach {
        $properties = @{
            Folder = $_
        }

        New-Object PSObject -Property $properties
    }
}
