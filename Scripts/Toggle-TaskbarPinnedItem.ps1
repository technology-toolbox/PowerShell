<#
.SYNOPSIS
Pins or unpins the specified application from the taskbar.

.PARAMETER ApplicationName
Specifies the name of the application to pin or unpin.

.EXAMPLE
.\Toggle-TaskbarMenuPinnedItem.ps1 "SQL Server 2014 Management Studio"
#>
[CmdletBinding()]
Param(
    [Parameter(Position = 1, Mandatory = $true)]
    $ApplicationName
)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Import-Module .\WASP\WASP.dll -Verbose:$false
}

Process
{
    Write-Verbose "Toggling taskbar pinned item ($ApplicationName)..."

    Select-Window -ActiveWindow |
        Send-Keys -Keys "^{ESC}"  # open Start menu

    Sleep -Milliseconds 200

    $activeWindow = Select-Window -ActiveWindow

    If ($activeWindow.Title -eq "Start menu")
    {
        $activeWindow | Send-Keys -Keys $ApplicationName # type app name
        Sleep -Milliseconds 300

        $activeWindow | Send-Keys -Keys "+{F10}" # open context menu
        Sleep -Milliseconds 200

        # select "Pin to Taskbar" or "Unpin from Taskbar"
        $activeWindow | Send-Keys -Keys "{DOWN 2}"
        $activeWindow | Send-Keys -Keys "{ENTER}"

        $activeWindow | Send-Keys -Keys "{ESC 3}" # close Start menu
    }
    Else
    {
        Throw "Unexpected window ($($activeWindow.Title))"
    }
}