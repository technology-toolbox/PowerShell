Param(
  [string] $Path = "Z:\NotBackedUp\Backups",
  [int] $NumberOfDaysToKeep = 14)

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

        Write-Host "$(Get-TimeStamp): Deleting $file...`r`n"
        Remove-Item $file -Force
      }
}