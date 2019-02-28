. $PSScriptRoot\..\Private\CreateHostsEntryObject.ps1
. $PSScriptRoot\..\Private\ParseHostsEntry.ps1
. $PSScriptRoot\..\Private\ParseHostsFile.ps1
. $PSScriptRoot\Get-Hostnames.ps1

Describe 'Get-Hostnames Tests' {
    [string] $hostsPath = `
        $env:WINDIR + '\System32\drivers\etc\hosts'

    Context '[hosts file does not exist]' {
        Mock Test-Path {return $false}

        $result = Get-Hostnames

        It 'Checks if hosts file exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath
                }
        }

        It 'Returns null when hosts file does not exist' {
            $result | Should Be $null
        }
    }

    Context '[Empty hosts file]' {
        Mock Test-Path {return $true}
        Mock Get-Content {return @()}

        $result = Get-Hostnames

        It 'Gets content from hosts file' {
            Assert-MockCalled Get-Content -Times 1 -Exactly
            Assert-MockCalled Get-Content -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath
                }
        }

        It 'Returns null when hosts file is empty' {
            $result | Should Be $null
        }
    }

    Context '[Simple hosts file]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# Comment 1',
            '#',
            '# Comment 2'
            '127.0.0.1       localhost')
        }

        $result = Get-Hostnames

        It 'Returns object with expected properties' {
            $result | Should BeOfType PSObject
            $result.IpAddress | Should Be '127.0.0.1'
            $result.Hostname | Should Be 'localhost'
        }
    }

    Context '[Hosts file with multiple items]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '127.0.0.1       localhost'
            '192.168.0.1     foo bar # fictitious hosts')
        }

        $result = Get-Hostnames

        It 'Returns array of objects with expected properties' {

            $result | Should BeOfType PSObject
            $result.IpAddress | Should Be @(
                '127.0.0.1', '192.168.0.1', '192.168.0.1')

            $result.Hostname | Should Be @('localhost', 'foo', 'bar')
        }
    }
}