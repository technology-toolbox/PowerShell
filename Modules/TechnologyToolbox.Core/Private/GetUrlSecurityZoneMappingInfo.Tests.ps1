. $PSScriptRoot\GetUrlSecurityZoneMappingInfo.ps1
. $PSScriptRoot\GetUrlSecurityZoneMapPath.ps1
. $PSScriptRoot\IsEscEnabled.ps1

Describe 'GetUrlSecurityZoneMappingInfo Tests (ESC enabled)' {
    Mock IsEscEnabled {return $true}

    Context '[Local intranet URL]' {
        $result = GetUrlSecurityZoneMappingInfo `
            -Pattern http://localhost

        It 'Sets Domain to expected value' {
            $result.Domain | Should Be 'localhost'
        }

        It 'Sets RegistryPath to expected value' {
            $result.RegistryPath |
                Should Be ('HKCU:\Software\Microsoft\Windows\CurrentVersion' `
                    + '\Internet Settings\ZoneMap\EscDomains\localhost')
        }

        It 'Sets Scheme to expected value' {
            $result.Scheme | Should Be 'http'
        }

        It 'Sets Subdomain to expected value' {
            $result.Subdomain | Should Be ''
        }
    }

    Context '[Top-level domain URL]' {
        $result = GetUrlSecurityZoneMappingInfo `
            -Pattern https://foobar.com

        It 'Sets Domain to expected value' {
            $result.Domain | Should Be 'foobar.com'
        }

        It 'Sets RegistryPath to expected value' {
            $result.RegistryPath |
                Should Be ('HKCU:\Software\Microsoft\Windows\CurrentVersion' `
                    + '\Internet Settings\ZoneMap\EscDomains\foobar.com')
        }

        It 'Sets Scheme to expected value' {
            $result.Scheme | Should Be 'https'
        }

        It 'Sets Subdomain to expected value' {
            $result.Subdomain | Should Be ''
        }
    }

    Context '[URL with subdomain]' {
        $result = GetUrlSecurityZoneMappingInfo `
            -Pattern https://www.foobar.com

        It 'Sets Domain to expected value' {
            $result.Domain | Should Be 'foobar.com'
        }

        It 'Sets RegistryPath to expected value' {
            $result.RegistryPath |
                Should Be ('HKCU:\Software\Microsoft\Windows\CurrentVersion' `
                    + '\Internet Settings\ZoneMap\EscDomains\foobar.com\www')
        }

        It 'Sets Scheme to expected value' {
            $result.Scheme | Should Be 'https'
        }

        It 'Sets Subdomain to expected value' {
            $result.Subdomain | Should Be 'www'
        }
    }
}

Describe 'GetUrlSecurityZoneMappingInfo Tests (ESC disabled)' {
    Mock IsEscEnabled {return $false}

    Context '[URL with subdomain]' {
        $result = GetUrlSecurityZoneMappingInfo `
            -Pattern https://www.foobar.com

        It 'Sets Domain to expected value' {
            $result.Domain | Should Be 'foobar.com'
        }

        It 'Sets RegistryPath to expected value' {
            $result.RegistryPath |
                Should Be ('HKCU:\Software\Microsoft\Windows\CurrentVersion' `
                    + '\Internet Settings\ZoneMap\Domains\foobar.com\www')
        }

        It 'Sets Scheme to expected value' {
            $result.Scheme | Should Be 'https'
        }

        It 'Sets Subdomain to expected value' {
            $result.Subdomain | Should Be 'www'
        }
    }
}