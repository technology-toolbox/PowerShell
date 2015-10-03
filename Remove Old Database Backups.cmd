@echo off

setlocal

set BACKUP_FOLDER=Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup
set DAYS_TO_KEEP=14

if NOT "%~1" == "" set BACKUP_FOLDER=%~1
if NOT "%~2" == "" set DAYS_TO_KEEP=%~2

PowerShell.exe -Command "& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1' -Path '%BACKUP_FOLDER%' -NumberOfDaysToKeep %DAYS_TO_KEEP%; Exit $LASTEXITCODE" >> "Remove Old Database Backups.log" 2>&1
EXIT %ERRORLEVEL%