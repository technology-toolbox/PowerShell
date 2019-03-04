. $PSScriptRoot\..\Private\GetInternetSecurityZoneMappingInfo.ps1
. $PSScriptRoot\..\Private\GetZoneMapPath.ps1
. $PSScriptRoot\..\Private\IsEscEnabled.ps1
. $PSScriptRoot\..\Private\RemoveRegistryKeyIfEmpty.ps1
. $PSScriptRoot\Remove-InternetSecurityZoneMapping.ps1

Describe 'Remove-InternetSecurityZoneMapping Tests (No ESC)' {
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

    Mock GetZoneMapPath {return $zoneMapPath}

    Context '[Domains registry key is empty]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains

        It 'Domain registry key does not exist' {
            Test-Path "$domainsRegistryPath\localhost" | Should Be $false
        }

        Mock Remove-ItemProperty {}

        Remove-InternetSecurityZoneMapping http://localhost

        It 'Does not remove registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 0
        }
    }

    Context '[Domain in zone map with multiple schemes]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \localhost
        #         - http (1)
        #         - https (1)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 1

        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name https -Value 1

        It 'Registry key should have two properties before removal' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty http |
                Should Be 1

            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty https |
                Should Be 1
        }

        Remove-InternetSecurityZoneMapping http://localhost

        It 'Removes registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Get-Member |
                Should Not Contain http
        }

        It 'Does not remove registry value for other scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty https |
                Should Be 1
        }
    }

    Context '[Domain in zone map with different scheme]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \foobar.com
        #         - http (4)

        New-Item "$domainsRegistryPath\foobar.com"
        Set-ItemProperty -Path "$domainsRegistryPath\foobar.com" `
            -Name http -Value 4

        Remove-InternetSecurityZoneMapping https://foobar.com

        It 'Does not remove registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\foobar.com" |
                Select-Object -ExpandProperty http |
                Should Be 4
        }
    }

    Context '[Domain in zone map with specified scheme (and no others)]' {
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

        Remove-InternetSecurityZoneMapping http://localhost

        It 'Removes registry key for domain' {
            Test-Path -Path "$domainsRegistryPath\localhost" | Should Be $false
        }
    }

    Context '[Remove subdomain]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \microsoft.com
        #         \www
        #           - http (2)

        New-Item "$domainsRegistryPath\microsoft.com"
        New-Item "$domainsRegistryPath\microsoft.com\www"
        Set-ItemProperty -Path "$domainsRegistryPath\microsoft.com\www" `
            -Name http -Value 2

        Remove-InternetSecurityZoneMapping http://www.microsoft.com

        It 'Removes registry key for domain' {
            Test-Path -Path "$domainsRegistryPath\microsoft.com" | Should Be $false
        }
    }

    Context '[Subdomain with different scheme (i.e. HTTPS -- not HTTP)]' {
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

        Remove-InternetSecurityZoneMapping http://www.foobar.com

        It 'Does not remove registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\foobar.com\www" |
                Select-Object -ExpandProperty https |
                Should Be 2
        }
    }

    Context '[Removes pattern specified in pipeline]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \localhost
        #         - http (1)
        #         - https (1)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 1

        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name https -Value 1

        It 'Registry key should have two properties before removal' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty http |
                Should Be 1

            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty https |
                Should Be 1
        }

        'http://localhost' | Remove-InternetSecurityZoneMapping

        It 'Removes registry value for scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Get-Member |
                Should Not Contain http
        }

        It 'Does not remove registry value for other scheme' {
            Get-ItemProperty -Path "$domainsRegistryPath\localhost" |
                Select-Object -ExpandProperty https |
                Should Be 1
        }
    }
}