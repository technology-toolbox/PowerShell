﻿<#
.SYNOPSIS
Clears all Windows event logs.

.DESCRIPTION
Clearing all of the Windows event logs is useful in development environments
(for example, to check if a computer reboots "cleanly" -- i.e. without any
errors).

.EXAMPLE
.\Clear-EventLogs.ps1

.NOTES
This script must be run with administrator privileges.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

wevtutil el | ForEach-Object { wevtutil cl $_ }
