﻿param(
    [string] $logFolder = "C:\inetpub\logs\LogFiles",
    [DateTime] $lastWriteTimeFilter = [DateTime]::Now.Date)
    
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

If ((Get-Module -Name Pscx) -eq $null)
{
    Import-Module .\Pscx
}

Get-ChildItem -LiteralPath $logFolder -Filter *.log -Recurse |
    ForEach-Object {
        [System.IO.FileInfo] $logFile = Get-Item -LiteralPath $_.FullName

        If ($logFile.LastWriteTime.Date.CompareTo(
            $lastWriteTimeFilter) -ge 0)
        {
            Write-Debug "Skipping log file ($($logFile.FullName))..."                
            return
        }

        Write-Host "Compressing log file ($($logFile.FullName))..."        
        Write-Zip -LiteralPath $_.FullName -NoClobber | Out-Null
        
        [string] $zipFile = $_.FullName + ".zip"
        
        $archiveEntry = Read-Archive -LiteralPath $zipFile
        
        If ($archiveEntry.Size -eq $logFile.Length)
        {
            Write-Host "Removing log file ($($logFile.FullName))..."
            Remove-Item $logFile
        }
    }
