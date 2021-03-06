﻿Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module Pscx -EA 0

function GetSolutionFile(
    [string] $path)
{
    If ([string]::IsNullOrEmpty($path) -eq $true)
    {
        Throw "Path must be specified."
    }

    $solutionFile = Get-ChildItem $path -Filter *.sln -Recurse

    If ($solutionFile -eq $null)
    {
        Throw "Solution file not found."
    }
    ElseIf ($solutionFile -is [Array])
    {
        Throw "More than one solution file was found."
    }

    return $solutionFile
}

function RemoveExtraneousItems(
    [string] $path)
{
    If ([string]::IsNullOrEmpty($path) -eq $true)
    {
        Throw "Path must be specified."
    }

    Write-Host "Removing extraneous items from folder ($path)..."

    Get-ChildItem $path -Include obj -Recurse |
        Remove-Item -Recurse
}

function ZipFolder(
    [IO.DirectoryInfo] $directory)
{
    If ($directory -eq $null)
    {
        Throw "Value cannot be null: directory"
    }

    Write-Host ("Creating zip file for folder (" + $directory.FullName + ")...")

    [IO.DirectoryInfo] $parentDir = $directory.Parent

    [string] $zipFileName

    If ($parentDir.FullName.EndsWith("\") -eq $true)
    {
        # e.g. $parentDir = "C:\"
        $zipFileName = $parentDir.FullName + $directory.Name + ".zip"
    }
    Else
    {
        $zipFileName = $parentDir.FullName + "\" + $directory.Name + ".zip"
    }

    If (Test-Path $zipFileName)
    {
        Throw "Zip file already exists ($zipFileName)."
    }

    Write-Zip $directory.FullName -OutputPath $zipFileName -IncludeEmptyDirectories
}

function PackageCodeSample(
    [string] $codeSampleFolder)
{
    If ([string]::IsNullOrEmpty($codeSampleFolder) -eq $true)
    {
        Throw "Code sample folder must be specified."
    }

    Write-Host ("Packaging code sample ($codeSampleFolder)...")

    If (Test-Path $codeSampleFolder)
    {
        Remove-Item $codeSampleFolder -Force -Recurse
    }

    [string] $parentFolder = [Io.Path]::GetDirectoryName($codeSampleFolder)
    [string] $codeSampleFolderBaseName = [Io.Path]::GetFileName(
        $codeSampleFolder)

    Push-Location $parentFolder

    $tf = "${env:ProgramFiles(x86)}" `
            + "\Microsoft Visual Studio 10.0\Common7\IDE\TF.exe"

    & $tf get $codeSampleFolderBaseName /force /recursive

    Pop-Location

    $solutionFile = GetSolutionFile $codeSampleFolder

    Push-Location $solutionFile.DirectoryName

    $msbuild = "${env:windir}" `
            + "\Microsoft.NET\Framework\v3.5\MSBuild.exe"

    & $msbuild $solutionFile.Name

    Pop-Location

    [IO.DirectoryInfo] $directory = Get-Item $codeSampleFolder

    RemoveExtraneousItems $directory

    ZipFolder $directory

    Write-Host -Fore Green ("Successfully packaged code sample (" `
        + $directory.FullName + ").")

}

#Remove-Item "C:\NotBackedUp\Fabrikam\Demo\Dev\SharePoint2010CodeCoverage.zip"

#PackageCodeSample "C:\NotBackedUp\Fabrikam\Demo\Dev\SharePoint2010CodeCoverage"
