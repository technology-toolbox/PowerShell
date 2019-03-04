. $PSScriptRoot\..\Private\GetZoneMapPath.ps1
. $PSScriptRoot\..\Private\IsEscEnabled.ps1
. $PSScriptRoot\Get-InternetSecurityZoneMapping.ps1

Describe 'Get-InternetSecurityZoneMapping Tests (No ESC)' {
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

        It 'Domains registry key is empty' {
            Get-ChildItem "$domainsRegistryPath" | Should Be $null
        }

        $result = Get-InternetSecurityZoneMapping

        It 'Returns null when Domains registry key is empty' {
            $result | Should Be $null
        }
    }

    Context '[Domains registry key with single domain (and multiple schemes)]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        New-Item "$domainsRegistryPath\windowsupdate.com"
        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name http -Value 2

        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name https -Value 2

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone | Should Be @('TrustedSites', 'TrustedSites')
            $result.Pattern |
                Should Be @('http://windowsupdate.com', 'https://windowsupdate.com')
        }
    }

    Context '[Domains registry key with single restricted domain (and multiple schemes)]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \foobar.com
        #         - http (4)
        #         - https (4)

        New-Item "$domainsRegistryPath\foobar.com"
        Set-ItemProperty -Path "$domainsRegistryPath\foobar.com" `
            -Name http -Value 4

        Set-ItemProperty -Path "$domainsRegistryPath\foobar.com" `
            -Name https -Value 4

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone | Should Be @('RestrictedSites', 'RestrictedSites')
            $result.Pattern |
                Should Be @('http://foobar.com', 'https://foobar.com')
        }
    }

    Context '[Domains registry key with multiple domains (unfiltered)]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \localhost
        #         - http (1)
        #         - https (1)
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 1

        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name https -Value 1

        New-Item "$domainsRegistryPath\windowsupdate.com"
        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name http -Value 2

        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name https -Value 2

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone |
                Should Be @(
                    'LocalIntranet', 'LocalIntranet',
                    'TrustedSites', 'TrustedSites')

            $result.Pattern |
                Should Be @(
                    'http://localhost', 'https://localhost',
                    'http://windowsupdate.com', 'https://windowsupdate.com')
        }
    }

    Context '[Domains registry key with multiple domains (filtered)]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \localhost
        #         - http (1)
        #         - https (1)
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 1

        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name https -Value 1

        New-Item "$domainsRegistryPath\windowsupdate.com"
        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name http -Value 2

        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name https -Value 2

        $result = Get-InternetSecurityZoneMapping -Zone LocalIntranet

        It 'Returns expected value' {
            $result.Zone |
                Should Be @(
                    'LocalIntranet', 'LocalIntranet')

            $result.Pattern |
                Should Be @('http://localhost', 'https://localhost')
        }
    }

    Context '[Domains registry key with subdomains]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \microsoft.com
        #         \*.windowsupdate
        #           - http (2)
        #           - https (2)
        #         \www
        #           - http (2)

        New-Item "$domainsRegistryPath\microsoft.com"

        New-Item "$domainsRegistryPath\microsoft.com\*.windowsupdate"
        Set-ItemProperty `
            -Path "$domainsRegistryPath\microsoft.com\*.windowsupdate" `
            -Name http -Value 2

        Set-ItemProperty `
            -Path "$domainsRegistryPath\microsoft.com\*.windowsupdate" `
            -Name https -Value 2

        New-Item "$domainsRegistryPath\microsoft.com\www"
        Set-ItemProperty -Path "$domainsRegistryPath\microsoft.com\www" `
            -Name http -Value 2

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone |
                Should Be @('TrustedSites', 'TrustedSites', 'TrustedSites')

            $result.Pattern |
                Should Be @(
                    'http://*.windowsupdate.microsoft.com',
                    'https://*.windowsupdate.microsoft.com',
                    'http://www.microsoft.com')
        }
    }
}

Describe 'Get-InternetSecurityZoneMapping Tests (ESC)' {
    Mock IsEscEnabled {return $true}

    [string] $zoneMapPath = 'TestRegistry:\ZoneMap'
    [string] $domainsRegistryPath = "$zoneMapPath\EscDomains"

    # Fake registry entries:
    #
    # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
    #   \ZoneMap
    #     \EscDomains

    New-Item "$zoneMapPath"
    New-Item "$domainsRegistryPath"

    Mock GetZoneMapPath {return $zoneMapPath}

    Context '[EscDomains registry key is empty]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \EscDomains

        It 'EscDomains registry key is empty' {
            Get-ChildItem "$domainsRegistryPath" | Should Be $null
        }

        $result = Get-InternetSecurityZoneMapping

        It 'Returns null when Domains registry key is empty' {
            $result | Should Be $null
        }
    }

    Context '[EscDomains registry key with single domain (and multiple schemes)]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \EscDomains
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        New-Item "$domainsRegistryPath\windowsupdate.com"
        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name http -Value 2

        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name https -Value 2

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone | Should Be @('TrustedSites', 'TrustedSites')
            $result.Pattern |
                Should Be @('http://windowsupdate.com', 'https://windowsupdate.com')
        }
    }

    Context '[EscDomains registry key with multiple domains]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \EscDomains
        #       \localhost
        #         - http (1)
        #         - https (1)
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        New-Item "$domainsRegistryPath\localhost"
        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name http -Value 1

        Set-ItemProperty -Path "$domainsRegistryPath\localhost" `
            -Name https -Value 1

        New-Item "$domainsRegistryPath\windowsupdate.com"
        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name http -Value 2

        Set-ItemProperty -Path "$domainsRegistryPath\windowsupdate.com" `
            -Name https -Value 2

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone |
                Should Be @(
                    'LocalIntranet', 'LocalIntranet',
                    'TrustedSites', 'TrustedSites')

            $result.Pattern |
                Should Be @(
                    'http://localhost', 'https://localhost',
                    'http://windowsupdate.com', 'https://windowsupdate.com')
        }
    }

    Context '[EscDomains registry key with subdomains]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \EscDomains
        #       \microsoft.com
        #         \*.windowsupdate
        #           - http (2)
        #           - https (2)
        #         \www
        #           - http (2)

        New-Item "$domainsRegistryPath\microsoft.com"

        New-Item "$domainsRegistryPath\microsoft.com\*.windowsupdate"
        Set-ItemProperty `
            -Path "$domainsRegistryPath\microsoft.com\*.windowsupdate" `
            -Name http -Value 2

        Set-ItemProperty `
            -Path "$domainsRegistryPath\microsoft.com\*.windowsupdate" `
            -Name https -Value 2

        New-Item "$domainsRegistryPath\microsoft.com\www"
        Set-ItemProperty -Path "$domainsRegistryPath\microsoft.com\www" `
            -Name http -Value 2

        $result = Get-InternetSecurityZoneMapping

        It 'Returns expected value' {
            $result.Zone |
                Should Be @('TrustedSites', 'TrustedSites', 'TrustedSites')

            $result.Pattern |
                Should Be @(
                    'http://*.windowsupdate.microsoft.com',
                    'https://*.windowsupdate.microsoft.com',
                    'http://www.microsoft.com')
        }
    }
}