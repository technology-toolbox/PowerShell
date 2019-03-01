. $PSScriptRoot\CreateHostsEntryObject.ps1
. $PSScriptRoot\ParseHostsEntry.ps1

Describe 'ParseHostsEntry Tests' {
    Context '[Comment line]' {
        $result = ParseHostsEntry -line '# A comment'

        It 'Has empty IP address' {
            $result.IpAddress | Should Be ''
        }

        It 'Has no hostnames' {
            $result.Hostnames | Should Be $null
        }

        It 'Sets comment to expected value' {
            $result.Comment | Should Be ' A comment'
        }
    }

    Context '[Line with single hostname]' {
        $result = ParseHostsEntry -line '127.0.0.1     localhost'

        It 'Sets IP address to expected value' {
            $result.IpAddress | Should Be '127.0.0.1'
        }

        It 'Sets hostnames to expected value' {
            $result.Hostnames | Should Be @('localhost')
        }

        It 'Has null comment' {
            $result.Comment | Should Be $null
        }
    }

    Context '[Line with single hostname and comment]' {
        $result = ParseHostsEntry `
            -line '127.0.0.1     localhost # Loopback address'

        It 'Sets IP address to expected value' {
            $result.IpAddress | Should Be '127.0.0.1'
        }

        It 'Sets hostnames to expected value' {
            $result.Hostnames | Should Be @('localhost')
        }

        It 'Sets comment to expected value' {
            $result.Comment | Should Be ' Loopback address'
        }
    }

    Context '[Line with multiples hostnames and comment]' {
        $result = ParseHostsEntry `
            -line '192.168.0.1     foo bar # Fictitious hosts'

        It 'Sets IP address to expected value' {
            $result.IpAddress | Should Be '192.168.0.1'
        }

        It 'Sets hostnames to expected value' {
            $result.Hostnames | Should Be @('foo', 'bar')
        }

        It 'Sets comment to expected value' {
            $result.Comment | Should Be ' Fictitious hosts'
        }
    }
}