. $PSScriptRoot\GetEnvironmentVariable.ps1

Describe 'GetEnvironmentVariable Tests' {
    Context '[COMPUTERNAME environment variable (Scope: Machine)]' {
        $result = GetEnvironmentVariable -Variable COMPUTERNAME -Target Machine

        It 'Returns expected value' {
            $result | Should Be $null
        }
    }

    Context '[COMPUTERNAME environment variable (Scope: Process)]' {
        $result = GetEnvironmentVariable -Variable COMPUTERNAME

        It 'Returns expected value' {
            $result | Should Be $env:COMPUTERNAME
        }
    }

    Context '[COMPUTERNAME environment variable (Scope: User)]' {
        $result = GetEnvironmentVariable -Variable COMPUTERNAME -Target User

        It 'Returns expected value' {
            $result | Should Be $null
        }
    }

    Context '[USERNAME environment variable (Scope: Machine)]' {
        $result = GetEnvironmentVariable -Variable USERNAME -Target Machine

        It 'Returns expected value' {
            $result | Should Be 'SYSTEM'
        }
    }

    Context '[USERNAME environment variable (Scope: Process)]' {
        $result = GetEnvironmentVariable USERNAME

        It 'Returns expected value' {
            $result | Should Be $env:USERNAME
        }
    }

    Context '[USERNAME environment variable (Scope: User)]' {
        $result = GetEnvironmentVariable -Variable USERNAME -Target User

        It 'Returns expected value' {
            $result | Should Be $null
        }
    }
}