Param(
  [string] $Path = "Z:\NotBackedUp\Backups",
  [int] $NumberOfDaysToKeep = 14,
  [string[]] $BackupFileExtensions = (".bak", ".trn"))

Begin
{
  Function Get-TimeStamp
  {
    Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  }
}

Process
{
  Write-Host "$(Get-TimeStamp): Removing old backups from $Path...`r`n"

  [DateTime] $timeLimit = (Get-Date).AddDays(-$NumberOfDaysToKeep)

  Get-ChildItem -Path $Path -Recurse -Force |
    Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $timeLimit } |
      ForEach-Object {
        [string] $file = $_.FullName

        If ($BackupFileExtensions.Contains($_.Extension) -eq $true)
        {
            Write-Host "$(Get-TimeStamp): Deleting $file...`r`n"
            Remove-Item $file -Force
        }
        Else
        {
            Write-Host ("$(Get-TimeStamp): Skipping file ($file) because it" `
                + " does not match the list of backup file extensions.`r`n")
        }
      }
}