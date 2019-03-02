. $PSScriptRoot\Remove-InternetSecurityZoneMapping.ps1

Describe 'Remove-InternetSecurityZoneMapping Tests (No ESC)' {
    [string] $zoneMapPath = 'HKCU:\Software\Microsoft\Windows' `
        + '\CurrentVersion\Internet Settings\ZoneMap'

    [string] $domainsRegistryPath = "$zoneMapPath\Domains"

    [string] $escRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup' `
        + '\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'

    Mock Get-ChildItem {Throw "Unsupported Path ($Path)"}
    Mock Get-Item {Throw "Unsupported Path ($Path)"}
    Mock New-Item {Throw 'New-Item should not be called'}
    Mock New-ItemProperty {Throw 'New-ItemProperty should not be called'}
    Mock Remove-Item {Throw "Unsupported Path ($Path)"}
    Mock Set-ItemProperty {Throw 'Set-ItemProperty should not be called'}
    Mock Test-Path {Throw "Unsupported Path ($Path)"}
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

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Remove-InternetSecurityZoneMapping http://localhost

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq "$domainsRegistryPath\localhost"
                }
        }

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
                http = 1
                https = 1
            }

        Mock Get-ChildItem {return $null} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $true} -ParameterFilter {
           $Path -eq "$domainsRegistryPath\localhost"
        }

        Remove-InternetSecurityZoneMapping http://localhost

        It 'Removes registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq "$domainsRegistryPath\localhost" -and
                    $Name -eq 'http'
                }
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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\foobar.com"
            }

        $fakeDomainRegistryKey | Add-Member ScriptMethod GetValue {
                return $null
            }

        $fakeDomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'foobar.com'
                http = 4
            }

        Mock Get-ChildItem {return $null} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com"
            }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com"
            }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $true} -ParameterFilter {
           $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Remove-InternetSecurityZoneMapping https://foobar.com

        It 'Does not remove registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 0
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
                http = 1
            }

        Mock Get-ChildItem {return $null} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $true} -ParameterFilter {
           $Path -eq "$domainsRegistryPath\localhost"
        }

        Remove-InternetSecurityZoneMapping http://localhost

        It 'Removes registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq "$domainsRegistryPath\localhost" -and
                    $Name -eq 'http'
                }
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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\microsoft.com"
            }

        $fakeSubdomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSParentPath = "$domainsRegistryPath\microsoft.com"
                PSPath = "$domainsRegistryPath\microsoft.com\www"
            }

        $fakeSubdomainRegistryKey | Add-Member ScriptMethod GetValue {
            return 2
        }

        $fakeSubdomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'www'
                http = 2
            }

        Mock Get-ChildItem {return $fakeSubdomainRegistryKey} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com"
            }

        Mock Get-ChildItem {return $null} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }

        Mock Get-Item {return @($fakeSubdomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\microsoft.com\www"
            }

        Mock Get-ItemProperty {return $fakeSubdomainSchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $true} -ParameterFilter {
           $Path -eq "$domainsRegistryPath\microsoft.com"
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\microsoft.com\www"
        }

        Remove-InternetSecurityZoneMapping http://www.microsoft.com

        It 'Reads expected registry key to check if domain exists' {
            Assert-MockCalled Test-Path -Times 2 -Exactly `
                -ParameterFilter {
                    $Path -eq "$domainsRegistryPath\microsoft.com"
                }
        }

        It 'Removes registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq "$domainsRegistryPath\microsoft.com\www" -and
                    $Name -eq 'http'
                }
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

        $fakeDomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSPath = "$domainsRegistryPath\foobar.com"
            }

        $fakeSubdomainRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSParentPath = "$domainsRegistryPath\foobar.com"
                PSPath = "$domainsRegistryPath\foobar.com\www"
            }

        $fakeSubdomainRegistryKey | Add-Member ScriptMethod GetValue {
            return 2
        }

        $fakeSubdomainSchemeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                PSChildName = 'www'
                https = 2
            }

        Mock Get-Item {return @($fakeSubdomainRegistryKey)} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\foobar.com\www"
            }

        Mock Get-ItemProperty {return $fakeSubdomainSchemeRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\foobar.com\www"
        }

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $false} -ParameterFilter {
           $Path -eq "$domainsRegistryPath\foobar.com"
        }

        Remove-InternetSecurityZoneMapping http://www.foobar.com

        It 'Does not removes registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 0
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
                http = 1
            }

        Mock Get-ChildItem {return $null} -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-ItemProperty {return $fakeDomainSchemeRegistryKey} `
            -ParameterFilter {
                $Path -eq "$domainsRegistryPath\localhost"
            }

        Mock Get-Item {return $fakeDomainRegistryKey} -ParameterFilter {
            $Path -eq "$domainsRegistryPath\localhost"
        }

        Mock Remove-ItemProperty {}
        Mock Test-Path {return $true} -ParameterFilter {
           $Path -eq "$domainsRegistryPath\localhost"
        }

        'http://localhost' | Remove-InternetSecurityZoneMapping

        It 'Removes registry value for scheme' {
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq "$domainsRegistryPath\localhost" -and
                    $Name -eq 'http'
                }
        }
    }
}