. $PSScriptRoot\IsEscEnabled.ps1

Describe 'IsEscEnabled Tests' {
    [string] $escRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Active Setup' `
        + '\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'

    Mock Get-ItemProperty {Throw "Mock Get-ItemProperty called with unexpected Path ($Path)"}
    Mock Test-Path {Throw "Mock Test-Path called with unexpected Path ($Path)"}

    Context '[ESC registry key is missing]' {
        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq $escRegistryPath
        }

        $result = IsEscEnabled

        It 'Checks if registry key exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly -ParameterFilter {
                $Path -eq $escRegistryPath
            }
        }

        It 'Returns expected value' {
            $result | Should Be $false
        }
    }

    Context '[ESC disabled]' {
        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq $escRegistryPath
        }

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                IsInstalled = 0
            }

        Mock Get-ItemProperty {return $fakeRegistryKey} `
            -ParameterFilter { $Path -eq $escRegistryPath }

        $result = IsEscEnabled

        It 'Returns expected value' {
            $result | Should Be $false
        }
    }

    Context '[ESC enabled]' {
        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq $escRegistryPath
        }

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                IsInstalled = 1
            }

        Mock Get-ItemProperty {return $fakeRegistryKey} `
            -ParameterFilter { $Path -eq $escRegistryPath }

        $result = IsEscEnabled

        It 'Returns expected value' {
            $result | Should Be $true
        }
    }
}