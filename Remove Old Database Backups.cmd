@echo off

setlocal

set BACKUP_FOLDER=Z:\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup

if NOT "%~1" == "" set BACKUP_FOLDER=%~1

PowerShell.exe -Command "& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1' -Path '%BACKUP_FOLDER%'; Exit $LASTEXITCODE" >> "Remove Old Database Backups.log" 2>&1
EXIT %ERRORLEVEL%