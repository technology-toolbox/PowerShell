. $PSScriptRoot\..\Private\GetUrlSecurityZoneMappingInfo.ps1
. $PSScriptRoot\..\Private\GetUrlSecurityZoneMapPath.ps1
. $PSScriptRoot\..\Private\IsEscEnabled.ps1
. $PSScriptRoot\Add-UrlSecurityZoneMapping.ps1

Describe 'Add-UrlSecurityZoneMapping Tests (No ESC)' {
    Mock IsEscEnabled {return $false}

    # Fake registry entries:
    #
    # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
    #   \ZoneMap
    #     \Domains

    [string] $zoneMapPath = 'TestRegistry:\ZoneMap'
    [string] $domainsRegistryPath = "$zoneMapPath\Domains"

    New-Item "$zoneMapPath"
    New-Item "$domainsRegistryPath"

    Mock GetUrlSecurityZoneMapPath {return $zoneMapPath}

    Context '[Domains registry key is empty]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains

        It 'Domain registry key does not already exist' {
            Test-Path "$domainsRegistryPath\localhost" | Should Be $false
        }

        Add-UrlSecurityZoneMapping `
            -Zone LocalIntranet `
            -Patterns http://localhost

        It 'Creates new registry key when domain does not exist' {
            Test-Path "$domainsRegistryPath\localhost" | Should Be $true
        }

        It 'Sets registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty http |
                Should Be 1
        }
    }

    Context '[Domain already in specified zone]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \localhost
        #         - http (1)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 1

        Mock Set-ItemProperty {}

        Add-UrlSecurityZoneMapping `
            -Zone LocalIntranet `
            -Patterns http://localhost

        It 'Does not set registry value for scheme' {
            Assert-MockCalled Set-ItemProperty -Times 0
        }
    }

    Context '[Domain in different zone]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \localhost
        #         - http (2)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 2

        Add-UrlSecurityZoneMapping `
            -Zone LocalIntranet `
            -Patterns http://localhost

        It 'Sets registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty http |
                Should Be 1
        }
    }

    Context '[Add top-level domain to Restricted Sites zone]' {
        It 'Domain registry key does not already exist' {
            Test-Path -Path "$domainsRegistryPath\foobar.com" | Should Be $false
        }

        Add-UrlSecurityZoneMapping `
            -Zone RestrictedSites `
            -Patterns http://foobar.com

        It 'Creates new registry key when domain does not exist' {
            Test-Path -Path "$domainsRegistryPath\foobar.com" | Should Be $true
        }

        It 'Sets registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\foobar.com" |
                Select-Object -ExpandProperty http |
                Should Be 4
        }
    }

    Context '[New subdomain]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains

        It 'Domain registry key does not already exist' {
            Test-Path -Path "$domainsRegistryPath\microsoft.com" |
                Should Be $false
        }

        Add-UrlSecurityZoneMapping `
            -Zone TrustedSites `
            -Patterns https://www.microsoft.com

        It 'Creates new registry key when subdomain does not exist' {
            Test-Path -Path "$domainsRegistryPath\microsoft.com\www" |
                Should Be $true
        }

        It 'Sets registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\microsoft.com\www" |
                Select-Object -ExpandProperty https |
                Should Be 2
        }
    }

    Context '[Subdomain already in specified zone]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \microsoft.com
        #         \www
        #           - https (2)

        New-Item "$domainsRegistryPath\microsoft.com"
        New-Item "$domainsRegistryPath\microsoft.com\www"
        Set-ItemProperty -Path "$domainsRegistryPath\microsoft.com\www" `
            -Name https -Value 2

        Mock Set-ItemProperty {}

        Add-UrlSecurityZoneMapping `
            -Zone TrustedSites `
            -Patterns http://www.microsoft.com

        It 'Does not set registry value for scheme' {
            Assert-MockCalled Set-ItemProperty -Times 0
        }
    }

    Context '[Subdomain in different zone]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \foobar.com
        #         \www
        #           - https (2)

        New-Item "$domainsRegistryPath\foobar.com"
        New-Item "$domainsRegistryPath\foobar.com\www"
        Set-ItemProperty -Path "$domainsRegistryPath\foobar.com\www" `
            -Name https -Value 2

        Add-UrlSecurityZoneMapping `
            -Zone RestrictedSites `
            -Patterns https://www.foobar.com

        It 'Sets registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\foobar.com\www" |
                Select-Object -ExpandProperty https |
                Should Be 4
        }
    }

    Context '[Adds domain specified in pipeline]' {
        It 'Domain registry key does not already exist' {
            Test-Path "$domainsRegistryPath\localhost" | Should Be $false
        }

        'http://localhost' | Add-UrlSecurityZoneMapping `
            -Zone LocalIntranet


        It 'Creates new registry key when domain does not exist' {
            Test-Path "$domainsRegistryPath\localhost" | Should Be $true
        }

        It 'Sets registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty http |
                Should Be 1
        }
    }
}