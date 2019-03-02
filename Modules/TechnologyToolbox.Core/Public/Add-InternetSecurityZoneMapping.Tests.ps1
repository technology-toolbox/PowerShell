. $PSScriptRoot\..\Private\AddPatternToInternetSecurityZone.ps1
. $PSScriptRoot\..\Private\IsEscEnabled.ps1
. $PSScriptRoot\Add-InternetSecurityZoneMapping.ps1

Describe 'Add-InternetSecurityZoneMapping Tests (No ESC)' {
    [string] $zoneMapPath = 'HKCU:\Software\Microsoft\Windows' `
        + '\CurrentVersion\Internet Settings\ZoneMap'

    [string] $domainsRegistryPath = "$zoneMapPath\Domains"

    [string] $escRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup' `
        + '\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'

    Mock Get-ChildItem {Throw "Mock Get-ChildItem called with unexpected Path ($Path)"}
    Mock Get-Item {Throw "Mock Get-Item called with unexpected Path ($Path)"}
    Mock New-Item {Throw "Mock New-Item called with unexpected Path ($Path)"}
    Mock New-ItemProperty {Throw "Mock New-ItemProperty called with unexpected Path ($Path)"}
    Mock Remove-Item {Throw "Mock Remove-Item called with unexpected Path ($Path)"}
    Mock Set-ItemProperty {Throw "Mock Set-ItemProperty called with unexpected Path ($Path)"}
    Mock Test-Path {Throw "Mock Test-Path called with unexpected Path ($Path)"}
    Mock Test-Path {return $false} -ParameterFilter {
        $Path -eq $escRegistryPath
    }

    Context '[Domains registry key is empty]' {
        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\localhost"
        }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValue {
            return @()
        }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock New-Item {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock New-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Set-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Add-InternetSecurityZoneMapping `
            -Zone LocalIntranet `
            -Patterns http://localhost

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }
        }

        It 'Creates new registry key when domain does not exist' {
            Assert-MockCalled New-Item -Times 1 -Exactly
            Assert-MockCalled New-Item -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }
        }

        It 'Sets registry value for scheme' {
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost" -and
                $Name -eq 'http' -and
                $PropertyType -eq 'DWORD' -and
                $Value -eq 1
            }
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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\localhost"
        }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValue {
            return 1
        }

        $fakeDomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSChildName = 'localhost'
            http        = 2
            https       = 2
        }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Add-InternetSecurityZoneMapping `
            -Zone LocalIntranet `
            -Patterns http://localhost

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }
        }

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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\localhost"
        }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValue {
            return 2
        }

        $fakeDomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSChildName = 'localhost'
            http        = 2
            https       = 2
        }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Set-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Add-InternetSecurityZoneMapping `
            -Zone LocalIntranet `
            -Patterns http://localhost

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }
        }

        It 'Sets registry value for scheme' {
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost" -and
                $Name -eq 'http' -and
                $Value -eq 1
            }
        }
    }

    Context '[Add top-level domain to Restricted Sites zone]' {
        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\foobar.com"
        }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValue {
            return @()
        }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Mock New-Item {return $false} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Mock New-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Add-InternetSecurityZoneMapping `
            -Zone RestrictedSites `
            -Patterns http://foobar.com

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com"
            }
        }

        It 'Creates new registry key when domain does not exist' {
            Assert-MockCalled New-Item -Times 1 -Exactly
            Assert-MockCalled New-Item -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com"
            }
        }

        It 'Sets registry value for scheme' {
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com" -and
                $Name -eq 'http' -and
                $PropertyType -eq 'DWORD' -and
                $Value -eq 4
            }
        }
    }

    Context '[New subdomain]' {
        # Fake registry entries:
        #
        # HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings
        #   \ZoneMap
        #     \Domains
        #       \microsoft.com

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\microsoft.com"
        }

        $fakeSubdomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSParentPath = "$domainsRegistryPath\microsoft.com"
            PSPath       = "$domainsRegistryPath\microsoft.com\www"
        }

        $fakeSubdomainRegistryKey | Add-Member ScriptMethod GetValue {
            return $null
        }

        Mock Get-Item {return @($fakeSubdomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }

        Mock Get-ItemProperty {return $fakeSubdomainSchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Mock New-Item {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Mock New-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com"
        }

        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Add-InternetSecurityZoneMapping `
            -Zone TrustedSites `
            -Patterns https://www.microsoft.com

        It 'Reads expected registry key to check if subdomain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }
        }

        It 'Creates new registry key when subdomain does not exist' {
            Assert-MockCalled New-Item -Times 1 -Exactly
            Assert-MockCalled New-Item -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }
        }

        It 'Sets registry value for scheme' {
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www" -and
                $Name -eq 'https' -and
                $PropertyType -eq 'DWORD' -and
                $Value -eq 2
            }
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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\microsoft.com"
        }

        $fakeSubdomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSParentPath = "$domainsRegistryPath\microsoft.com"
            PSPath       = "$domainsRegistryPath\microsoft.com\www"
        }

        $fakeSubdomainRegistryKey | Add-Member ScriptMethod GetValue {
            return 2
        }

        Mock Get-Item {return @($fakeSubdomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }

        Mock Get-ItemProperty {return $fakeSubdomainSchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Add-InternetSecurityZoneMapping `
            -Zone TrustedSites `
            -Patterns http://www.microsoft.com

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }
        }

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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\foobar.com"
        }

        $fakeSubdomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSParentPath = "$domainsRegistryPath\foobar.com"
            PSPath       = "$domainsRegistryPath\foobar.com\www"
        }

        $fakeSubdomainRegistryKey | Add-Member ScriptMethod GetValue {
            return 1
        }

        Mock Get-Item {return @($fakeSubdomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com\www"
            }

        Mock Get-ItemProperty {return $fakeSubdomainSchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com\www"
        }

        Mock Set-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com\www"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com\www"
        }

        Add-InternetSecurityZoneMapping `
            -Zone RestrictedSites `
            -Patterns https://www.foobar.com

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com\www"
            }
        }

        It 'Sets registry value for scheme' {
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com\www" -and
                $Name -eq 'https' -and
                $Value -eq 4
            }
        }
    }

    Context '[Adds domains specified in pipeline]' {
        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            PSPath = "$domainsRegistryPath\localhost"
        }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValue {
            return @()
        }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock New-Item {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock New-ItemProperty {} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        @('http://localhost') | Add-InternetSecurityZoneMapping `
            -Zone LocalIntranet

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }
        }

        It 'Creates new registry key when domain does not exist' {
            Assert-MockCalled New-Item -Times 1 -Exactly
            Assert-MockCalled New-Item -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }
        }

        It 'Sets registry value for scheme' {
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost" -and
                $Name -eq 'http' -and
                $PropertyType -eq 'DWORD' -and
                $Value -eq 1
            }
        }
    }
}