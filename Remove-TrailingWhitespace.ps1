<#
.SYNOPSIS
Removes trailing whitespace from each line in the specified file.

.PARAMETER Path
Specifies the path to a file. Wildcards are permitted. The parameter name
("Path") is optional.

.PARAMETER LiteralPath
Specifies the path to a file. Unlike Path, the value of LiteralPath is used
exactly as it is typed. No characters are interpreted as wildcards. If the path
includes escape characters, enclose it in single quotation marks. Single
quotation marks tell Windows PowerShell not to interpret any characters as
escape sequences.

.EXAMPLE
Remove-TrailingWhitespace.ps1 C:\MyClass.cs

.EXAMPLE
Remove-TrailingWhitespace.ps1 *.ps1
#>
[CmdletBinding(DefaultParameterSetName="Path")]
param(
    [parameter(Position = 0, Mandatory = $true, ParameterSetName = "Path",
        ValueFromPipeline = $true)]
    [string[]] $Path,
    [parameter(Position = 0, Mandatory = $false,
        ParameterSetName = "LiteralPath")]
    [string[]] $LiteralPath,
    [switch] $RemoveBlankLines
)

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    [bool] $isInputFromPipeline = $false

    If ($PSCmdlet.ParameterSetName -eq "Path")
    {
        $isInputFromPipeline =
            ($PSBoundParameters.ContainsKey("Path") -eq $false)
    }

    function GetEncodingShortName(
        [System.Text.Encoding] $encoding)
    {
        If ($encoding -eq [Text.Encoding]::Default)
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
}

process
{
    If ($isInputFromPipeline -eq $true)
    {
        $items = $_
    }
    Else
    {
        If ($PSCmdlet.ParameterSetName -eq "Path")
        {
            $items = Resolve-Path $Path
        }
        ElseIf ($PSCmdlet.ParameterSetName -eq "LiteralPath")
        {
            $items = $LiteralPath
        }
    }

    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

    $getFileEncodingScriptPath = Join-Path $scriptPath "Get-FileEncoding.ps1"

    $items | foreach {
        [string] $item = $_

        Write-Progress -Activity $MyInvocation.MyCommand `
            -Status "Processing item: $item"

        [System.Text.Encoding] $encoding = & $getFileEncodingScriptPath $item

        [string] $encodingShortName = GetEncodingShortName $encoding

        Write-Debug "Encoding: $encodingShortName"

        [int] $linesModified = 0
        [int] $linesRemoved = 0

        $trimmedContent = Get-Content $item | ForEach-Object {
            [string] $line = $_
            [string] $trimmedLine = $line.TrimEnd()

            If ($trimmedLine -ne $line)
            {
                $linesModified++
            }

            If ($RemoveBlankLines -eq $true `
                -and [string]::IsNullOrEmpty($trimmedLine) -eq $true)
            {
                $linesRemoved++
            }
            Else
            {
                Write-Output $trimmedLine
            }
        }

        If ($linesModified -gt 0 -or $linesRemoved -gt 0)
        {
            $trimmedContent | Out-File $item -Encoding $encodingShortName
        }
        ElseIf ($linesModified -eq 0)
        {
            Write-Debug "The file does not contain any trailing whitespace."
        }
        ElseIf ($RemoveBlankLines -eq $true `
            -and $linesRemoved -eq 0)
        {
            Write-Debug "The file does not contain any blank lines."
        }
    }
}
