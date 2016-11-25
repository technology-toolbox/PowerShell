<#
.SYNOPSIS
Gets HTML content from the Windows clipboard.

.DESCRIPTION
Parses HTML content from the Windows clipboard. If the clipboard does not
contain HTML content, an error is thrown.

.PARAMETER Fragment
If specified, then only the HTML "fragment" is returned (i.e. without the
enclosing <body> and <html> elements).

.EXAMPLE
.\Get-ClipboardHtml.ps1

<html>
    <body>
        <!--StartFragment--><h1>Foo bar</h1><!--EndFragment-->
    </body>
</html>

.EXAMPLE
.\Get-ClipboardHtml.ps1 -Fragment

<h1>Foo bar</h1>
#>
[CmdletBinding()]
Param(
    [Switch] $Fragment)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Add-Type -AssemblyName System.Windows.Forms

    Function ParsePosition($line)
    {
        Write-Debug "Parsing position from line ($line)..."

        [string[]] $parts = $line -split ":"

        If ($parts.Length -ne 2)
        {
            Throw ("Cannot parse position from line ($line)" `
                + " because it is not the expected format" `
                + " ({label}:{position}).")
        }

        [int] $position = $parts[1]

        return $position
    }
}

Process
{
    [string] $clipboardContent = [System.Windows.Forms.Clipboard]::GetText(
        [System.Windows.Forms.TextDataFormat]::Html)

    If ([string]::IsNullOrEmpty($clipboardContent) -eq $true)
    {
        Throw "Clipboard does not contain HTML content."
    }

    Write-Verbose ("Clipboard HTML content:" + ([System.Environment]::NewLine) `
        + $clipboardContent)

    [string[]] $lines = $clipboardContent.Split(
        @([System.Environment]::NewLine),
        [StringSplitOptions]::None)

    If ($lines.Length -lt 5)
    {
        Throw "The clipboard content does not contain at least 5 lines."
    }

    If ($lines[0].StartsWith("Version:") -eq $false)
    {
        Throw ("Line 1 of the clipboard content does not start with" `
            + " `"Version:`".")
    }

    If ($lines[1].StartsWith("StartHTML:") -eq $false)
    {
        Throw ("Line 2 of the clipboard content does not start with" `
            + " `"StartHTML:`".")
    }

    If ($lines[2].StartsWith("EndHTML:") -eq $false)
    {
        Throw ("Line 3 of the clipboard content does not start with" `
            + " `"EndHTML:`".")
    }

    If ($lines[3].StartsWith("StartFragment:") -eq $false)
    {
        Throw ("Line 4 of the clipboard content does not start with" `
            + " `"StartFragment:`".")
    }

    If ($lines[4].StartsWith("EndFragment:") -eq $false)
    {
        Throw ("Line 5 of the clipboard content does not start with" `
            + " `"EndFragment:`".")
    }

    [int] $htmlStartIndex = ParsePosition $lines[1]
    [int] $htmlEndIndex = ParsePosition $lines[2]
    [int] $fragmentStartIndex = ParsePosition $lines[3]
    [int] $fragmentEndIndex = ParsePosition $lines[4]

    Write-Debug "htmlStartIndex: $htmlStartIndex"
    Write-Debug "htmlEndIndex: $htmlEndIndex"
    Write-Debug "fragmentStartIndex: $fragmentStartIndex"
    Write-Debug "fragmentEndIndex: $fragmentEndIndex"

    [int] $start = 0
    [int] $length = 0

    If ($Fragment)
    {
        $start = $fragmentStartIndex
        $length = $fragmentEndIndex - $start
    }
    Else
    {
        $start = $htmlStartIndex
        $length = $htmlEndIndex - $start
    }

    [string] $html = $clipboardContent.Substring($start, $length)

    $html
}