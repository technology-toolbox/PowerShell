<#
.SYNOPSIS
Removes trailing whitespace from each line in the specified file.

.PARAMETER LiteralPath
Specifies the path to a file.

.EXAMPLE
Remove-TrailingWhitespace C:\MyClass.cs
#>
param(
    [parameter(Mandatory=$true)]
    [string] $LiteralPath
)

$ErrorActionPreference = "Stop"

function GetEncodingShortName(
    $encoding)
{
    If ($encoding -eq [System.Text.Encoding]::Default)
    {
        return "Default"
    }

    Switch ($encoding.EncodingName)
    {
        "Unicode (UTF-7)" { return "UTF7" }
        "Unicode (UTF-8)" { return "UTF8" }
        "Unicode (UTF-32)" { return "UTF32" }
        "US-ASCII" { return "ASCII" }
        "Unicode (Big-Endian)" { return "BigEndianUnicode" }
        default { return $encoding.EncodingName }
    }
}

$encoding = & .\Get-FileEncoding.ps1 $LiteralPath

[string] $encodingShortName = GetEncodingShortName $encoding

Write-Debug "Encoding: $encodingShortName"

$trimmedContent = Get-Content $LiteralPath | ForEach-Object { $_.TrimEnd(); }

$trimmedContent | Out-File $LiteralPath -Encoding $encodingShortName
