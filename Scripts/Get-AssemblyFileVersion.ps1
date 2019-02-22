<#
.SYNOPSIS
Gets the "assembly file version" from a file.

.DESCRIPTION
The Get-AssemblyFileVersion cmdlet gets the "assembly file version" from the
item at the location specified by the path, such as a C# source file or a .NET
assembly.

The "assembly file version" is specified using the AssemblyFileVersionAttribute.

.PARAMETER Path
Specifies the path to a .NET source file or assembly. Currently, this cmdlet
supports C# and VB.NET source files.

.EXAMPLE
.\Get-AssemblyFileVersion.ps1 C:\Windows\Microsoft.NET\assembly\GAC_MSIL\System\v4.0_4.0.0.0__b77a5c561934e089\System.dll

4.7.2556.0

Description
-----------
This command returns the version of an assembly in the Global Assembly Cache.

.EXAMPLE
.\Get-AssemblyFileVersion.ps1 C:\Foobar\AssemblyVersionInfo.cs

4.0.706.0

Description
-----------
This command returns the version specified in a C# source file as follows:

[assembly: System.Reflection.AssemblyFileVersion("4.0.706.0")]

.LINK
https://msdn.microsoft.com/en-us/library/system.reflection.assemblyfileversionattribute.aspx

#>
[CmdletBinding()]
Param(
    [Parameter(Position=0, Mandatory, ValueFromPipeLine=$true)]
    [string] $Path
)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function GetAssemblyFileVersionFromAssembly
    {
        Param([string] $Path)

        [string] $assemblyFileVersion = $null
        
        [Reflection.Assembly] $assembly = [Reflection.Assembly]::LoadFile($Path)

        $attributes = $assembly.GetCustomAttributes(
            [Reflection.AssemblyFileVersionAttribute],
            $false);

        If ($attributes.Length -gt 0)
        {
            $assemblyFileVersion =
                ([Reflection.AssemblyFileVersionAttribute]$attributes[0]).Version
        }

        return $assemblyFileVersion
    }

    Function GetAssemblyFileVersionFromSourceFile
    {
        Param([string] $Path)

        [string] $assemblyFileVersion = $null
        
        [string] $content = Get-Content -Path $Path -Raw

        [string] $pattern =
            "[Aa]ssembly:[\s]*" `
            + "(?:System\.Reflection\.)?" `
            + "AssemblyFileVersion[\s]*" `
            + '\("(.*)"\)'

        [Text.RegularExpressions.Match] $match =
            [RegEx]::Match($content, $pattern)

        If ($match.Success)
        {
            $assemblyFileVersion = $match.Groups[1].Value
        }

        return $assemblyFileVersion
    }
}

Process
{
    Write-Verbose "Get AssemblyFileVersion from file ($Path)..."

    [string] $assemblyFileVersion = $null

    [string] $fileExtension = [IO.Path]::GetExtension($Path)

    If ($fileExtension -in (".cs", ".vb"))
    {
        $assemblyFileVersion = GetAssemblyFileVersionFromSourceFile $Path
    }
    ElseIf ($fileExtension -in (".dll", ".exe"))
    {
        $assemblyFileVersion = GetAssemblyFileVersionFromAssembly $Path
    }
    Else
    {
        throw "Unsupported file extension ($fileExtension)."
    }

    Write-Verbose "AssemblyFileVersion: $assemblyFileVersion"

    If ([string]::IsNullOrEmpty($assemblyFileVersion) -eq $true)
    {
        Write-Warning "AssemblyFileVersion is not specified in file ($Path)."
    }
    Else
    {
        $assemblyFileVersion
    }
}
