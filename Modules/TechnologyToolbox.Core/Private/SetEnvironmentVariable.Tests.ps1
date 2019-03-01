. $PSScriptRoot\SetEnvironmentVariable.ps1

Describe 'SetEnvironmentVariable Tests' {
    Context '[FOOBAR environment variable (Scope: Process)]' {
        SetEnvironmentVariable -Variable FOOBAR -Value foobar

        It 'Returns expected value' {
            $env:FOOBAR | Should Be 'foobar'
        }
    }
}