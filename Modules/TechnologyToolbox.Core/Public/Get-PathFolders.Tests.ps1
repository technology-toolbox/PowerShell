. $PSScriptRoot\..\Private\GetEnvironmentVariable.ps1
. $PSScriptRoot\Get-PathFolders.ps1

Describe 'Get-PathFolders Tests' {
    Context '[Path environment variable (Scope: Machine)]' {
        Mock GetEnvironmentVariable {return 'C:\windows\system32;C:\windows'}

        $result = Get-PathFolders

        It 'Returns array of path folders' {
            $result | Should Be @('C:\windows\system32', 'C:\windows')
        }
    }

    Context '[Path environment variable (Scope: Process)]' {
        Mock GetEnvironmentVariable {return 'C:\windows\system32;C:\windows;C:\Users\foo'}

        $result = Get-PathFolders

        It 'Returns array of path folders' {
            $result | Should Be @('C:\windows\system32', 'C:\windows', 'C:\Users\foo')
        }
    }

    Context '[Path environment variable (Scope: User)]' {
        Mock GetEnvironmentVariable {return 'C:\Users\foo'}

        $result = Get-PathFolders

        It 'Returns array of path folders' {
            $result | Should Be @('C:\Users\foo')
        }
    }

    Context '[Path environment variable not set (Scope: User)]' {
        Mock GetEnvironmentVariable {return $null}

        $result = Get-PathFolders

        It 'Returns array of path folders' {
            $result | Should Be $null
        }
    }
}