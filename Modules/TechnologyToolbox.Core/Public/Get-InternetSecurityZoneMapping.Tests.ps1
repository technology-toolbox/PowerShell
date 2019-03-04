. $PSScriptRoot\..\Private\GetZoneMapPath.ps1
. $PSScriptRoot\..\Private\IsEscEnabled.ps1
. $PSScriptRoot\Get-InternetSecurityZoneMapping.ps1

Describe 'Get-InternetSecurityZoneMapping Tests (No ESC)' {
    [string] $zoneMapPath = 'HKCU:\Software\Microsoft\Windows' `
        + '\CurrentVersion\Internet Settings\ZoneMap'

    [string] $domainsRegistryPath = "$zoneMapPath\Domains"

    [string] $escRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup' `
        + '\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'

    Mock Get-ChildItem {Throw "Mock Get-ChildItem called with unexpected Path ($Path)"}
    Mock Get-Item {Throw "Mock Get-Item called with unexpected Path ($Path)"}
    Mock Test-Path {Throw "Mock Test-Path called with unexpected Path ($Path)"}
    Mock Test-Path {return $false} -ParameterFilter {
        $Path -eq $escRegistryPath
    }

    Context '[Domains registry key is empty]' {
        Mock Get-ChildItem {return @()} -ParameterFilter {
            $Path -eq $domainsRegistryPath
        }

        $result = Get-InternetSecurityZoneMapping

        It 'Reads expected registry key' {
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $domainsRegistryPath
                }
        }

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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\windowsupdate.com"
            }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'windowsupdate.com'
                http = 2
                https = 2
            }

        Mock Get-ChildItem {return @($fakeDomainRegistryKey)} -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\foobar.com"
            }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'foobar.com'
                http = 4
                https = 4
            }

        Mock Get-ChildItem {return @($fakeDomainRegistryKey)} -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com"
            }

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

        $fakeDomain1RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\localhost"
            }

        $fakeDomain1RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomain1SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'localhost'
                http = 1
                https = 1
            }

        $fakeDomain2RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\windowsupdate.com"
            }

        $fakeDomain2RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomain2SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'windowsupdate.com'
                http = 2
                https = 2
            }

        Mock Get-ChildItem {
                return @($fakeDomain1RegistryKey, $fakeDomain2RegistryKey)} `
            -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

        Mock Get-ItemProperty {return $fakeDomain1SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Get-ItemProperty {return $fakeDomain2SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\windowsupdate.com"
        }

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

        $fakeDomain1RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\localhost"
            }

        $fakeDomain1RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomain1SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'localhost'
                http = 1
                https = 1
            }

        $fakeDomain2RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\windowsupdate.com"
            }

        $fakeDomain2RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomain2SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'windowsupdate.com'
                http = 2
                https = 2
            }

        Mock Get-ChildItem {
                return @($fakeDomain1RegistryKey, $fakeDomain2RegistryKey)} `
            -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

        Mock Get-ItemProperty {return $fakeDomain1SchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ItemProperty {return $fakeDomain2SchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\microsoft.com"
            }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValueNames {
            return @()
        }

        $fakeSubdomain1RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSParentPath = "$domainsRegistryPath\microsoft.com"
                PSPath = "$domainsRegistryPath\microsoft.com\*.windowsupdate"
            }

        $fakeSubdomain1RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeSubdomain1SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = '*.windowsupdate'
                http = 2
                https = 2
            }

        $fakeSubdomain2RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSParentPath = "$domainsRegistryPath\microsoft.com"
                PSPath = "$domainsRegistryPath\microsoft.com\www"
            }

        $fakeSubdomain2RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http')
        }

        $fakeSubdomain2SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'www'
                http = 2
            }

        Mock Get-ChildItem {return @($fakeDomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @($fakeSubdomain1RegistryKey, $fakeSubdomain2RegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com"
            }

        Mock Get-ItemProperty {return $fakeSubdomain1SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\*.windowsupdate"
        }

        Mock Get-ItemProperty {return $fakeSubdomain2SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

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
    [string] $zoneMapPath = 'HKCU:\Software\Microsoft\Windows' `
        + '\CurrentVersion\Internet Settings\ZoneMap'

    [string] $domainsRegistryPath = "$zoneMapPath\EscDomains"

    [string] $escRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup' `
        + '\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'

    Mock Get-ChildItem {Throw "Mock Get-ChildItem called with unexpected Path ($Path)"}
    Mock Get-Item {Throw "Mock Get-Item called with unexpected Path ($Path)"}
    Mock Test-Path {Throw "Mock Test-Path called with unexpected Path ($Path)"}
    Mock Test-Path {return $true} -ParameterFilter {
        $Path -eq $escRegistryPath
    }

    Mock Get-ItemProperty {
        return New-Object `
            -TypeName psobject `
            -Property @{
                IsInstalled = 1
            }
        } `
        -ParameterFilter { $Path -eq $escRegistryPath }

    Context '[EscDomains registry key is empty]' {
        Mock Get-ChildItem {return @()} -ParameterFilter {
            $Path -eq $domainsRegistryPath
        }

        $result = Get-InternetSecurityZoneMapping

        It 'Reads expected registry key' {
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $domainsRegistryPath
                }
        }

        It 'Returns null when Domains registry key is empty' {
            $result | Should Be $null
        }
    }

    Context '[EscDomains registry key with single domain (and multiple schemes)]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\windowsupdate.com"
            }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'windowsupdate.com'
                http = 2
                https = 2
            }

        Mock Get-ChildItem {return @($fakeDomainRegistryKey)} -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

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
        #     \Domains
        #       \localhost
        #         - http (1)
        #         - https (1)
        #       \windowsupdate.com
        #         - http (2)
        #         - https (2)

        $fakeDomain1RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\localhost"
            }

        $fakeDomain1RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomain1SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'localhost'
                http = 1
                https = 1
            }

        $fakeDomain2RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\windowsupdate.com"
            }

        $fakeDomain2RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeDomain2SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'windowsupdate.com'
                http = 2
                https = 2
            }

        Mock Get-ChildItem {
                return @($fakeDomain1RegistryKey, $fakeDomain2RegistryKey)} `
            -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ChildItem {return @()} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\windowsupdate.com"
            }

        Mock Get-ItemProperty {return $fakeDomain1SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Get-ItemProperty {return $fakeDomain2SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\windowsupdate.com"
        }

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
        #     \Domains
        #       \microsoft.com
        #         \*.windowsupdate
        #           - http (2)
        #           - https (2)
        #         \www
        #           - http (2)

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\microsoft.com"
            }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValueNames {
            return @()
        }

        $fakeSubdomain1RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSParentPath = "$domainsRegistryPath\microsoft.com"
                PSPath = "$domainsRegistryPath\microsoft.com\*.windowsupdate"
            }

        $fakeSubdomain1RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http', 'https')
        }

        $fakeSubdomain1SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = '*.windowsupdate'
                http = 2
                https = 2
            }

        $fakeSubdomain2RegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSParentPath = "$domainsRegistryPath\microsoft.com"
                PSPath = "$domainsRegistryPath\microsoft.com\www"
            }

        $fakeSubdomain2RegistryKey | Add-Member ScriptMethod GetValueNames {
            return @('http')
        }

        $fakeSubdomain2SchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'www'
                http = 2
            }

        Mock Get-ChildItem {return @($fakeDomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq $domainsRegistryPath
            }

        Mock Get-ChildItem {return @($fakeSubdomain1RegistryKey, $fakeSubdomain2RegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com"
            }

        Mock Get-ItemProperty {return $fakeSubdomain1SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\*.windowsupdate"
        }

        Mock Get-ItemProperty {return $fakeSubdomain2SchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

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