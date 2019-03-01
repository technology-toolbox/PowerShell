. $PSScriptRoot\CreateHostsEntryObject.ps1
. $PSScriptRoot\ParseHostsEntry.ps1
. $PSScriptRoot\ParseHostsFile.ps1

Describe 'ParseHostsFile Tests' {
    [string] $hostsPath = `
        $env:WINDIR + '\System32\drivers\etc\hosts'

    Context '[hosts file does not exist]' {
        Mock Test-Path {return $false}

        $result = ParseHostsFile

        It 'Checks if hosts file exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath
                }
        }

        It 'Returns null' {
            $result | Should Be $null
        }
    }

    Context '[Empty hosts file]' {
        Mock Test-Path {return $true}
        Mock Get-Content {return @()}

        $result = ParseHostsFile

        It 'Returns null' {
            $result | Should Be $null
        }
    }

    Context '[Simple hosts file]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# Comment 1',
            '#',
            '# Comment 2'
            '127.0.0.1       localhost'
            '192.168.0.1     foo bar # Ficitious hosts')
        }

        $result = ParseHostsFile

        It 'Parses hosts file' {
            $result | Should HaveCount 5

            $result[0].Comment | Should Be ' Comment 1'

            $result[1].Comment | Should Be ''

            $result[2].Comment | Should Be ' Comment 2'

            $result[3].IpAddress | Should Be @('127.0.0.1')
            $result[3].Hostnames | Should Be @('localhost')

            $result[4].IpAddress | Should Be @('192.168.0.1')
            $result[4].Hostnames | Should Be @('foo', 'bar')
            $result[4].Comment | Should Be @(' Ficitious hosts')
        }
    }
}