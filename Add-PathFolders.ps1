<#
.SYNOPSIS
Adds one or more folders to the Path environment variable.

.PARAMETER Folders
Specifies the folders to add to the Path environment variable..

.PARAMETER EnvironmentVariableTarget
Specifies the "scope" to use for the Path environment variable ("Process",
"Machine", or "User"). Defaults to "Process" if the parameter is not specified.

.EXAMPLE
.\Add-PathFolders.ps1 C:\NotBackedUp\Public\Toolbox
#>
param(
    [parameter(Mandatory=$true)]
    [string[]] $Folders,
    [string] $EnvironmentVariableTarget = "Process")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[int] $foldersAdded = 0

[string[]] $pathFolders = [Environment]::GetEnvironmentVariable(
    "Path",
    $EnvironmentVariableTarget) -Split ";"

$folderList = New-Object System.Collections.ArrayList

$pathFolders | foreach {
    $folderList.Add($_) | Out-Null
}

$Folders | foreach {
    [string] $folder = $_

    [bool] $folderFound = $false

    $folderList | foreach {
        If ([string]::Compare($_, $folder, $true) -eq 0)
        {
            Write-Host ("The folder ($folder) is already included" `
                + " in the Path environment variable.")

            $folderFound = $true
            return
        }
    }

    If ($folderFound -eq $false)
    {
        Write-Host "Adding folder ($folder) to Path environment variable..."
        $folderList.Add($folder) | Out-Null

        $foldersAdded++
    }
}

If ($foldersAdded -eq 0)
{
    Write-Host ("No changes to the Path environment variable are" `
        + " necessary.")

    Exit
}
Else
{
    [string] $delimitedFolders = $folderList -Join ";"

    [Environment]::SetEnvironmentVariable(
        "Path",
        $delimitedFolders,
        $EnvironmentVariableTarget)
}

Write-Host -Fore Green ("Successfully added folders ($Folders) to Path" `
    + " environment variable.")
