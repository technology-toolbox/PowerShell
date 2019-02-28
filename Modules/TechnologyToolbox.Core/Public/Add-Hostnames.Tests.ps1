. $PSScriptRoot\Add-Hostnames.ps1

Describe 'Add-Hostnames Tests' {
    [string] $hostsPath = `
        $env:WINDIR + '\System32\drivers\etc\hosts'

    Context '[hosts file does not exist]' {
        Mock Test-Path {return $false}
        Mock Set-Content {}

        Add-Hostnames -IPAddress 127.0.0.1 -Hostnames foobar

        $expectedContent =
@'
127.0.0.1	foobar
'@

        It 'Checks if hosts file exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $hostsPath
                }
        }

        It 'Set hosts file content' {
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

    Context '[Empty hosts file]' {
        Mock Test-Path {return $true}
        Mock Get-Content {return @()}
        Mock Set-Content {}

        Add-Hostnames -IPAddress 127.0.0.1 -Hostnames foobar

        $expectedContent =
@'
127.0.0.1	foobar
'@

        It 'Set hosts file content' {
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

    Context '[hosts file contains specified IP address and hostname]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# Comment 1',
            '#',
            '# Comment 2'
            '127.0.0.1       localhost')
        }

        Mock Set-Content {}

        Add-Hostnames -IPAddress 127.0.0.1 -Hostnames localhost

        It 'Does not set hosts file content' {
            Assert-MockCalled Set-Content -Times 0 -Exactly
        }
    }

    Context '[hosts file does not contain specified hostname]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# A comment',
            '127.0.0.1       localhost')
        }

        Mock Set-Content {
            Write-Host "Mocked Set-Content called"
            Write-Host "    Path: $Path"
            Write-Host "    Value: $Value"
            Write-Host "    Force: $Force"
            Write-Host "    Encoding: $Encoding"
        }

        Add-Hostnames -IPAddress 192.168.0.1 -Hostnames foobar

        $expectedContent =
@'
# A comment
127.0.0.1	localhost
192.168.0.1	foobar
'@

        It 'Set hosts file content' {
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

    Context '[hosts file does not contain hostnames specified in pipeline]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# A comment',
            '127.0.0.1       localhost')
        }

        Mock Set-Content {}

        'foo', 'bar' | Add-Hostnames -IPAddress 192.168.0.1

        $expectedContent =
@'
# A comment
127.0.0.1	localhost
192.168.0.1	foo
192.168.0.1	bar
'@

        It 'Set hosts file content' {
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

    Context '[hosts file contains specified IP address]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# A comment',
            '127.0.0.1       localhost')
        }

        Mock Set-Content {}

        Add-Hostnames -IPAddress 127.0.0.1 -Hostnames foobar

        $expectedContent =
@'
# A comment
127.0.0.1	localhost
127.0.0.1	foobar
'@

        It 'Set hosts file content' {
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

    Context '[hosts file contains specified hostname with different IP address]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '# A comment',
            '127.0.0.1       localhost foobar')
        }

        Mock Set-Content {}

        $errorMessage = 'The hosts file already contains the specified' `
            + ' hostname (foobar) and it is mapped to a different address' `
            + ' (127.0.0.1).'

        It 'Should throw exception' {
            { Add-Hostnames -IPAddress 192.168.0.1 -Hostnames foobar } |
                Should Throw $errorMessage
        }
    }

    Context '[hosts file contains multiple hostnames for single IP address]' {
        Mock Test-Path {return $true}
        Mock Get-Content { return @(
            '192.168.0.1       foo bar # Fictitious hosts')
        }

        Mock Set-Content {}

        Add-Hostnames -IPAddress 10.0.0.1 -Hostnames foobar

        $expectedContent =
@'
192.168.0.1	foo bar # Fictitious hosts
10.0.0.1	foobar
'@

        It 'Set hosts file content' {
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