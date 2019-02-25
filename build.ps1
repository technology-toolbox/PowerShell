[CmdletBinding()]
Param()

Begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
}

Process {
    # Run tests with code coverage
    $codeCoverageFiles = Get-ChildItem `
        -Path $PSScriptRoot\Modules\* `
        -Include *.ps1, *.psm1 `
        -Exclude *.Tests.* `
        -Recurse

    Invoke-Pester -CodeCoverage $codeCoverageFiles
}