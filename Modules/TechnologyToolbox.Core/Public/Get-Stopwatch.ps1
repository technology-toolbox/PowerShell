[CmdletBinding()]
Param()

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
}

Process
{
    return [System.Diagnostics.Stopwatch]::StartNew()
}