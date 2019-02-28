. $PSScriptRoot\Remove-Hostnames.ps1

Describe 'Remove-Hostnames Tests' {
    [string] $hostsPath = `
        $env:WINDIR + '\System32\drivers\etc\hosts'

    Context '[hosts file does not exist]' {
        Mock Test-Path {return $false}
        Mock Set-Content {}

        Remove-Hostnames -Hostnames foobar

        It 'Checks if hosts file exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath
                }
        }

        It 'Does not set hosts file content' {
            Assert-MockCalled Set-Content -Times 0 -Exactly
        }
    }

    Context '[Empty hosts file]' {
        Mock Test-Path {return $true}
        Mock Get-Content {return @()}
        Mock Set-Content {}

        Remove-Hostnames -Hostnames foobar

        It 'Does not set hosts file content' {
            Assert-MockCalled Set-Content -Times 0 -Exactly
        }
    }

    Context '[hosts file does not contain specified hostname]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# Comment 1',
            '#',
            '# Comment 2'
            '127.0.0.1       localhost')
        }

        Mock Set-Content {}

        Remove-Hostnames -Hostnames foobar

        It 'Does not set hosts file content' {
            Assert-MockCalled Set-Content -Times 0 -Exactly
        }
    }

    Context '[Hosts file contains specified hostname]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '127.0.0.1       localhost'
            '192.168.0.1     foobar # Fictitious host')
        }

        $expectedContent = '127.0.0.1	localhost'

        Mock Set-Content {}

        Remove-Hostnames -Hostnames foobar

        It 'Removes specified hostname from hosts file' {
            Assert-MockCalled Set-Content -Times 1 -Exactly
            Assert-MockCalled Set-Content -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath -and
                    $Value -eq $expectedContent -and
                    $Force -eq $true -and
                    $Encoding -eq 'ASCII'
                }
        }
    }

    Context '[Hosts file containing specified hostname and other aliases]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '127.0.0.1       localhost'
            '192.168.0.1     foo bar # Fictitious hosts')
        }

        $expectedContent =
'127.0.0.1	localhost' + [Environment]::NewLine `
+ '192.168.0.1	bar # Fictitious hosts'

        Mock Set-Content {}

        Remove-Hostnames -Hostnames foo

        It 'Removes specified hostname from hosts file' {
            Assert-MockCalled Set-Content -Times 1 -Exactly
            Assert-MockCalled Set-Content -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath -and
                    $Value -eq $expectedContent -and
                    $Force -eq $true -and
                    $Encoding -eq 'ASCII'
                }
        }
    }

    Context '[Hosts file containing specified hostnames in pipeline]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '127.0.0.1       localhost foobar'
            '192.168.0.1     foo bar # fictitious host')
        }

        $expectedContent = '127.0.0.1	localhost foobar'

        Mock Set-Content {}

        'foo', 'bar' | Remove-Hostnames

        It 'Removes specified hostname from hosts file' {
            Assert-MockCalled Set-Content -Times 1 -Exactly
            Assert-MockCalled Set-Content -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath -and
                    $Value -eq $expectedContent -and
                    $Force -eq $true -and
                    $Encoding -eq 'ASCII'
                }
        }
    }
}