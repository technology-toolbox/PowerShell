<#
.SYNOPSIS
Sets the "assembly file version" in a .NET source file.

.DESCRIPTION
The Set-AssemblyFileVersion cmdlet sets the "assembly file version" in the
source file at the location specified by the path (e.g. AssemblyVersionInfo.cs).

The "assembly file version" is specified using the AssemblyFileVersionAttribute.

.PARAMETER Version
Specifies the value for the AssemblyVersionFileAttribute. 

.PARAMETER Path
Specifies the path to a .NET source file. Currently, this cmdlet supports C# and
VB.NET source files.

.EXAMPLE
.\Set-AssemblyFileVersion.ps1 -Version 1.0.0.0 -Path AssemblyVersionInfo.cs

Description
-----------
If the specified file already exists, the AssemblyFileVersionAttribute is set to
"1.0.0.0" (appending the attribute to the file, as necessary). If the file does
not exist, it will be created with the following content:

[assembly: System.Reflection.AssemblyFileVersion("1.0.0.0")]


.EXAMPLE
$assemblyVersionInfoFile = "AssemblyVersionInfo.cs"
.\Get-AssemblyFileVersion.ps1 -Path $assemblyVersionInfoFile |
    .\Edit-AssemblyVersion.ps1 -Build Increment -AsString |
    select -ExpandProperty NewVersion |
    .\Set-AssemblyFileVersion.ps1 -Path $assemblyVersionInfoFile -Confirm:$false -Verbose

VERBOSE: Set AssemblyFileVersion in file (AssemblyVersionInfo.cs)...
VERBOSE: Current AssemblyFileVersion: 1.0.0.0
VERBOSE: New AssemblyFileVersion: 1.0.1.0
VERBOSE: Performing the operation "Set-AssemblyFileVersion.ps1" on target "AssemblyVersionInfo.cs".
VERBOSE: The file has been updated.

Description
-----------
This command reads the current "assembly file version" from a file, increments
the build number, and then writes the new version into the source file.

.LINK
https://msdn.microsoft.com/en-us/library/system.reflection.assemblyfileversionattribute.aspx

#>
[CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "High")]
Param(
    [Parameter(Position=0, Mandatory, ValueFromPipeLine=$true)]
    [Version] $Version,
    [Parameter(Position=1, Mandatory)]
    [string] $Path
)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function SetAssemblyFileVersionInSourceFile
    {
        Param(
            [Version] $Version,
            [string] $Path)

        [string] $content = $null
        
        If (Test-Path $Path)
        {
            $content = Get-Content -Path $Path -Raw
        }

        [string] $pattern =
            "[Aa]ssembly:[\s]*" `
            + "(?:System\.Reflection\.)?" `
            + "AssemblyFileVersion[\s]*" `
            + '\("(.*)"\)'

        [Text.RegularExpressions.Match] $match =
            [RegEx]::Match($content, $pattern)

        If ($match.Success)
        {
            $currentAssemblyFileVersion = $match.Groups[1].Value

            Write-Verbose ("Current AssemblyFileVersion:" `
                + " $currentAssemblyFileVersion")

            Write-Verbose ("New AssemblyFileVersion:" `
                + " $Version")

            $stringToReplace = $match.Value

            Write-Debug "stringToReplace: $stringToReplace"

            $replacementString = $stringToReplace.Replace(
                $currentAssemblyFileVersion,
                $Version.ToString())

            Write-Debug "replacementString: $replacementString"

            $content = $content.Remove(
                $match.Index,
                $match.Length)

            $content = $content.Insert(
                $match.Index,
                $replacementString)

            $content = $content.TrimEnd()
        }
        Else
        {
            # Append AssemblyFileVersionAttribute to file
            [string] $fileExtension = [IO.Path]::GetExtension($Path)

            If ($fileExtension -eq ".cs")
            {
                $content = $content + [Environment]::NewLine `
                    + '[assembly: System.Reflection.AssemblyFileVersion("' `
                        + $Version.ToString() + '")]'
            }
            ElseIf ($fileExtension -eq ".vb")
            {
                $content = $content + [Environment]::NewLine `
                    + '<Assembly: System.Reflection.AssemblyFileVersion("' `
                        + $Version.ToString() + '")>'
            }
            Else
            {
                throw "Unsupported file extension ($fileExtension)."
            }
        }

        If ($PSCmdlet.ShouldProcess($Path) -eq $true)
        {
            Set-Content -Value $content -Path $Path
            Write-Verbose ("The file has been updated.")
        }
    }
}

Process
{
    Write-Verbose "Set AssemblyFileVersion in file ($Path)..."

    [string] $fileExtension = [IO.Path]::GetExtension($Path)

    If ($fileExtension -in (".cs", ".vb"))
    {
        SetAssemblyFileVersionInSourceFile -Version $Version -Path $Path
    }
    Else
    {
        throw "Unsupported file extension ($fileExtension)."
    }
}
