PowerShell.exe -Command "& 'C:\NotBackedUp\Public\Toolbox\PowerShell\Remove-OldBackups.ps1'; Exit $LASTEXITCODE" >> "Remove Old Backups.log" 2>&1
EXIT %ERRORLEVEL%