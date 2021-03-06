. $PSScriptRoot\..\Private\GetEnvironmentVariable.ps1
. $PSScriptRoot\..\Private\SetEnvironmentVariable.ps1
. $PSScriptRoot\Get-PathFolders.ps1
. $PSScriptRoot\Add-PathFolders.ps1

Describe 'Add-PathFolders Tests' {
    Context '[Path environment variable does not exist (Scope: User)]' {
        Mock GetEnvironmentVariable {return $null}
        Mock SetEnvironmentVariable {}

        Add-PathFolders 'C:\Users\foo' -EnvironmentVariableTarget User

        $expectedPath = 'C:\Users\foo'

        It 'Gets Path environment variable for User scope' {
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Target -eq 'User'
                }
        }

        It 'Sets Path environment variable' {
            Assert-MockCalled SetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled SetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Value -eq $expectedPath -and
                    $Target -eq 'User'
                }
        }
    }

    Context '[Path environment variable contains folder (Scope: User)]' {
        Mock GetEnvironmentVariable {return 'C:\Users\foo'}
        Mock SetEnvironmentVariable {}

        Add-PathFolders 'C:\Users\foo' -EnvironmentVariableTarget User

        It 'Gets Path environment variable for User scope' {
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Target -eq 'User'
                }
        }

        It 'Does not set Path environment variable' {
            Assert-MockCalled SetEnvironmentVariable -Times 0
        }
    }

    Context '[Path environment variable does not contain folder (Scope: User)]' {
        Mock GetEnvironmentVariable {return 'C:\Users\foo'}
        Mock SetEnvironmentVariable {}

        Add-PathFolders 'C:\Temp' -EnvironmentVariableTarget User

        $expectedPath = 'C:\Users\foo;C:\Temp'

        It 'Gets Path environment variable for User scope' {
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Target -eq 'User'
                }
        }

        It 'Sets Path environment variable' {
            Assert-MockCalled SetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled SetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Value -eq $expectedPath -and
                    $Target -eq 'User'
                }
        }
    }

    Context '[Path folders specified in pipeline]' {
        Mock GetEnvironmentVariable {
            return 'C:\windows\system32;C:\windows'
        }

        Mock SetEnvironmentVariable {}

        'C:\Users\foo', 'C:\Temp' |
            Add-PathFolders -EnvironmentVariableTarget Process

        $expectedPath = 'C:\windows\system32;C:\windows;C:\Users\foo;C:\Temp'

        It 'Gets Path environment variable for Process scope' {
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled GetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Target -eq 'Process'
                }
        }

        It 'Sets Path environment variable' {
            Assert-MockCalled SetEnvironmentVariable -Times 1 -Exactly
            Assert-MockCalled SetEnvironmentVariable -Times 1 -Exactly `
                -ParameterFilter {
                    $Variable -eq 'Path' -and
                    $Value -eq $expectedPath -and
                    $Target -eq 'Process'
                }
        }
    }
}