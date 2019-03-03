. $PSScriptRoot\RemoveRegistryKeyIfEmpty.ps1

Describe 'RemoveRegistryKeyIfEmpty Tests' {
    Mock Get-ChildItem {Throw "Mock Get-ChildItem called with unexpected Path ($Path)"}
    Mock Get-Item {Throw "Mock Get-Item called with unexpected Path ($Path)"}
    Mock Remove-Item {Throw "Mock Remove-Item called with unexpected Path ($Path)"}
    Mock Test-Path {Throw "Mock Test-Path called with unexpected Path ($Path)"}

    [string] $fakeRegistryPath = 'HKCU:\Foobar'

    Context '[Registry key does not exist]' {
        Mock Test-Path {return $false} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        RemoveRegistryKeyIfEmpty $fakeRegistryPath

        It 'Checks if registry key exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }
    }

    Context '[Empty registry key]' {
        Mock Get-ChildItem {return @()} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Get-ItemProperty {return @()} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Remove-Item {} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        RemoveRegistryKeyIfEmpty $fakeRegistryPath

        It 'Checks if registry key exists' {
            Assert-MockCalled Test-Path -Times 1 -Exactly
            Assert-MockCalled Test-Path -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }

        It 'Checks if registry key has child items' {
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }

        It 'Checks if registry key has properties' {
            Assert-MockCalled Get-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Get-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }

        It 'Removes registry key' {
            Assert-MockCalled Remove-Item -Times 1 -Exactly
            Assert-MockCalled Remove-Item -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }
    }

    Context '[Registry key with child item]' {
        $fakeRegistryKey = New-Object -TypeName psobject

        Mock Get-ChildItem {return @($fakeRegistryKey)} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Remove-Item {} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        RemoveRegistryKeyIfEmpty $fakeRegistryPath

        It 'Checks if registry key has child items' {
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }

        It 'Does not remove registry key' {
            Assert-MockCalled Remove-Item -Times 0
        }
    }

    Context '[Registry key with property]' {
        $fakeRegistryKey = New-Object -TypeName psobject

        Mock Get-ChildItem {return @()} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Get-ItemProperty {return @($fakeRegistryKey)} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Remove-Item {} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        Mock Test-Path {return $true} -ParameterFilter {
            $Path -eq $fakeRegistryPath
        }

        RemoveRegistryKeyIfEmpty $fakeRegistryPath

        It 'Checks if registry key has child items' {
            Assert-MockCalled Get-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Get-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $fakeRegistryPath
                }
        }

        It 'Does not remove registry key' {
            Assert-MockCalled Remove-Item -Times 0
        }
    }
}