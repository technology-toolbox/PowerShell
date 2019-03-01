. $PSScriptRoot\CreateHostsEntryObject.ps1

Describe 'CreateHostsEntryObject Tests' {
    Context '[Only comment specified]' {
        $result = CreateHostsEntryObject `
            -comment 'A comment'

        It 'Has empty IP address' {
            $result.IpAddress | Should Be ''
        }

        It 'Has no hostnames' {
            $result.Hostnames | Should Be @()
        }

        It 'Sets comment to expected value' {
            $result.Comment | Should Be 'A comment'
        }
    }

    Context '[Single hostname without comment]' {
        $result = CreateHostsEntryObject `
            -ipAddress 127.0.0.1 `
            -hostnames localhost

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

    Context '[Multiple hostnames with comment]' {
        $result = CreateHostsEntryObject `
            -ipAddress 192.168.0.1 `
            -hostnames foo, bar `
            -comment 'Fictitious hosts'

        It 'Sets IP address to expected value' {
            $result.IpAddress | Should Be '192.168.0.1'
        }

        It 'Sets hostnames to expected value' {
            $result.Hostnames | Should Be @('foo', 'bar')
        }

        It 'Sets comment to expected value' {
            $result.Comment | Should Be 'Fictitious hosts'
        }
    }
}