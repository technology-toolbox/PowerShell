<#
.SYNOPSIS
Removes one or more folders from the Path environment variable.

.PARAMETER Folders
Specifies the folders to remove from the Path environment variable..

.PARAMETER EnvironmentVariableTarget
Specifies the "scope" to use for the Path environment variable ("Process",
"Machine", or "User"). Defaults to "Process" if the parameter is not specified.

.EXAMPLE
.\Remove-PathFolders.ps1 C:\NotBackedUp\Public\Toolbox
#>
param(
    [parameter(Mandatory=$true)]
    [string[]] $Folders,
    [string] $EnvironmentVariableTarget = "Process")

$ErrorActionPreference = "Stop"

[int] $foldersRemoved = 0

[string[]] $pathFolders = [Environment]::GetEnvironmentVariable(
    "Path",
    $EnvironmentVariableTarget) -Split ";"

$folderList = New-Object System.Collections.ArrayList

$pathFolders | foreach {
    $folderList.Add($_) | Out-Null
}

$Folders | foreach {
    [string] $folder = $_

    for ([int] $i = 0; $i -lt $folderList.Count; $i++)
    {
        If ([string]::Compare($folderList[$i], $folder, $true) -eq 0)
        {
            Write-Host "Removing folder ($folder) from Path environment variable..."
            $folderList.RemoveAt($i)
            $i--

            $foldersRemoved++
        }
    }
}

If ($foldersRemoved -eq 0)
{
    Write-Host ("No changes to the Path environment variable are" `
        + " necessary.")

    Exit
}

[string] $delimitedFolders = $folderList -Join ";"

[Environment]::SetEnvironmentVariable(
    "Path",
    $delimitedFolders,
    $EnvironmentVariableTarget)

Write-Host -Fore Green ("Successfully removed folders ($Folders) from Path" `
    + " environment variable.")