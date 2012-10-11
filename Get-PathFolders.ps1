<#
.SYNOPSIS
Gets the list of folders specified in the PATH environment variable.

.EXAMPLE
Get-PathFolders

Folder
------
C:\Windows\system32\WindowsPowerShell\v1.0\
C:\Windows\system32
C:\Windows
C:\Windows\System32\Wbem
...
#>

[string[]] $path = $env:Path -Split ";"

If ($path -ne $null)
{
    $path | foreach {
        $properties = @{
            Folder = $_
        }

        New-Object PSObject -Property $properties
    }
}