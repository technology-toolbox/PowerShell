[CmdletBinding()]
Param(
    [System.Diagnostics.Stopwatch] $Stopwatch =
        $(Throw "Value cannot be null: Stopwatch"),
    [System.ConsoleColor] $ForegroundColor =
        [System.ConsoleColor]::Cyan,
    [string] $Prefix = $null,
    [string] $Suffix = $null)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
}

Process
{
    $timespan = $Stopwatch.Elapsed

    $formattedTime = [string]::Format(
        "{0:00}:{1:00}:{2:00}.{3:000}",
        $timespan.Hours,
        $timespan.Minutes,
        $timespan.Seconds,
        $timespan.Milliseconds)

    Write-Host `
        -ForegroundColor $ForegroundColor `
        ($Prefix + "Elapsed time: $formattedTime" + $Suffix)
}