Import-Module $PSScriptRoot\..\TechnologyToolbox.Core

Describe 'TechnologyToolbox.Core Tests' {
    It 'Exports all public functions' {
        $commands = Get-Command -Module TechnologyToolbox.Core |
            Select-Object -ExpandProperty Name

        $publicScripts  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude *.Tests.* )

        foreach ($script in $publicScripts) {
            $script.BaseName | Should BeIn $commands
        }
    }
}

Remove-Module TechnologyToolbox.Core