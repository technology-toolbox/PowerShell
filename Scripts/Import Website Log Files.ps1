<#
CREATE SCHEMA Staging

DROP TABLE Staging.WebsiteLog

CREATE TABLE Staging.WebsiteLog
(
    LogFilename NVARCHAR(260) NOT NULL,
    RowNumber INT NOT NULL,
    EntryTime DATETIME NOT NULL,
    SiteName NVARCHAR(255) NOT NULL,
    ServerName NVARCHAR(255) NOT NULL,
    ServerIpAddress NVARCHAR(255) NOT NULL,
    Method NVARCHAR(255) NOT NULL,
    UriStem NVARCHAR(2048) NOT NULL,
    UriQuery NVARCHAR(MAX),
    Port INT NOT NULL,
    Username NVARCHAR(255),
    ClientIpAddress NVARCHAR(255) NOT NULL,
    HttpVersion NVARCHAR(255),
    UserAgent NVARCHAR(255) NOT NULL,
    Cookie NVARCHAR(MAX),
    Referrer NVARCHAR(MAX),
    Hostname NVARCHAR(255) NOT NULL,
    HttpStatus INT NOT NULL,
    HttpSubstatus INT NOT NULL,
    Win32Status INT NOT NULL,
    BytesFromServerToClient INT,
    BytesFromClientToServer INT,
    TimeTaken INT NOT NULL
)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module .\Pscx -EA 0

function ArchiveLogFiles(
    [string] $httpLogPath)
{
    If ([string]::IsNullOrEmpty($httpLogPath) -eq $true)
    {
        Throw "The log path must be specified."
    }

    [string] $httpLogArchive = $httpLogPath + "\Archive"

    Write-Host "Archiving log files..."

    If ((Test-Path $httpLogArchive) -eq $false)
    {
        Write-Host "Creating archive folder for log files..."
        New-Item -ItemType directory -Path $httpLogArchive | Out-Null
    }

    Get-ChildItem $httpLogPath -Filter "*.zip" |
        ForEach-Object {
            Move-Item $_.FullName $httpLogArchive
        }

    Get-ChildItem $httpLogPath -Filter "*.log" |
        ForEach-Object {
            Move-Item $_.FullName $httpLogArchive
        }
}

function ExtractLogFiles(
    [string] $httpLogPath)
{
    If ([string]::IsNullOrEmpty($httpLogPath) -eq $true)
    {
        Throw "The log path must be specified."
    }

    Write-Host "Extracting compressed log files..."

    Get-ChildItem $httpLogPath -Filter "*.zip" |
        ForEach-Object {
            Expand-Archive $_ -OutputPath $httpLogPath
        }
}

function ImportLogFiles(
    [string] $databaseServer = $(Throw("Value must be specified: databaseServer.")),
    [string] $databaseName = $(Throw("Value must be specified: databaseName.")),
    [string] $httpLogPath = $(Throw("Value must be specified: httpLogPath.")))
{
    [int] $logFileCount = (Get-Item "$httpLogPath\*.log" | Measure-Object).Count

    If ($logFileCount -lt 1)
    {
        return
    }

    [string] $logParser = $null

    If ($env:PROCESSOR_ARCHITECTURE -eq "x86")
    {
        $logParser = "${env:ProgramFiles}" `
            + "\Log Parser 2.2\LogParser.exe"
    }
    Else
    {
        $logParser = "${env:ProgramFiles(x86)}" `
            + "\Log Parser 2.2\LogParser.exe"
    }

    [string] $query = `
        "SELECT" `
            + " LogFilename" `
            + ", RowNumber" `
            + ", TO_TIMESTAMP(date, time) AS EntryTime" `
            + ", s-sitename AS SiteName" `
            + ", s-computername AS ServerName" `
            + ", s-ip AS ServerIpAddress" `
            + ", cs-method AS Method" `
            + ", cs-uri-stem AS UriStem" `
            + ", cs-uri-query AS UriQuery" `
            + ", s-port AS Port" `
            + ", cs-username AS Username" `
            + ", c-ip AS ClientIpAddress" `
            + ", cs-version AS HttpVersion" `
            + ", cs(User-Agent) AS UserAgent" `
            + ", cs(Cookie) AS Cookie" `
            + ", cs(Referer) AS Referrer" `
            + ", cs-host AS Hostname" `
            + ", sc-status AS HttpStatus" `
            + ", sc-substatus AS HttpSubstatus" `
            + ", sc-win32-status AS Win32Status" `
            + ", sc-bytes AS BytesFromServerToClient" `
            + ", cs-bytes AS BytesFromClientToServer" `
            + ", time-taken AS TimeTaken" `
        + " INTO $schemaName.WebsiteLog" `
        + " FROM $httpLogPath\*.log"

    [string] $connectionString = "Driver={SQL Server Native Client 10.0};" `
        + "Server=$databaseServer;Database=$databaseName;Trusted_Connection=yes;"

    [string[]] $parameters = @()

    $parameters += $query
    $parameters += "-i:W3C"
    $parameters += "-o:SQL"
    $parameters += "-oConnString:$connectionString"

    Write-Debug "Parameters: $parameters"

    Write-Host "Importing log files to database..."
    & $logParser $parameters
}

function RemoveLogFilesAlreadyProcessed(
    [string] $httpLogPath)
{
    If ([string]::IsNullOrEmpty($httpLogPath) -eq $true)
    {
        Throw "The log path must be specified."
    }

    Write-Host "Removing log files that were already processed..."

    Get-ChildItem $httpLogPath -Filter *.zip |
        ForEach-Object {
            [string] $archiveZipFile = "$httpLogPath\Archive\" + $_.Name

            If (Test-Path -LiteralPath $archiveZipFile)
            {
                Write-Debug ("Removing log file ($_) because it has already" `
                    + " been processed...")

                Remove-Item $_.FullName
            }

            If (Test-Path -LiteralPath $_.FullName)
            {
                [string] $archiveLogFile = "$httpLogPath\Archive\" + $_.BaseName

                If (Test-Path -LiteralPath $archiveLogFile)
                {
                    Write-Debug ("Moving log zip file ($_) because it has already" `
                        + " been processed...")

                    Move-Item $_.FullName $archiveZipFile
                }
            }
        }

    Get-ChildItem $httpLogPath -Filter *.log |
        ForEach-Object {
            [string] $archiveFile = "$httpLogPath\Archive\$($_.Name)"

            If (Test-Path -LiteralPath $archiveFile)
            {
                Write-Debug ("Removing log file ($_.Name) because it has already" `
                    + " been processed...")

                Remove-Item $_.FullName
            }

            If (Test-Path -LiteralPath $_.FullName)
            {
                $archiveFile = "$httpLogPath\Archive\$($_.Name).zip"

                If (Test-Path -LiteralPath $archiveFile)
                {
                    Write-Debug ("Removing log file ($_.Name) because it has already" `
                        + " been processed...")

                    Remove-Item $_.FullName
                }
            }
        }
}

function RemoveLogFilesFromToday(
    [string] $logRootFolder)
{
    [string] $temp = Get-Date -UFormat "%y%m%d"

    [string] $logFileForToday = "u_ex" + $temp + ".log"

    Write-Host "Removing log files from today ($logFileForToday)..."

    Get-ChildItem $logRootFolder -Filter $logFileForToday -Recurse |
        ForEach-Object {
            Remove-Item -LiteralPath $_.FullName
        }
}

function Main
{
    [string] $databaseServer = "BEAST"
    [string] $databaseName = "Caelum_Warehouse"
    [string] $schemaName = "Staging"

    [string] $logRootFolder = "C:\inetpub\wwwroot\www.technologytoolbox.com\httplog"

    RemoveLogFilesFromToday $logRootFolder

    [string] $httpLogPath = $logRootFolder

    RemoveLogFilesAlreadyProcessed $httpLogPath

    ExtractLogFiles $httpLogPath

    ImportLogFiles $databaseServer $databaseName $httpLogPath

    ArchiveLogFiles $httpLogPath

    Write-Host -Fore Green "Successfully imported log files."
}

Main
