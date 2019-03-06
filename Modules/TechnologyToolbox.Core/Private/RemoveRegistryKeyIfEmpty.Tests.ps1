. $PSScriptRoot\RemoveRegistryKeyIfEmpty.ps1

Describe 'RemoveRegistryKeyIfEmpty Tests' {
    New-Item 'TestRegistry:\Empty'
    New-Item 'TestRegistry:\KeyWithChild'
    New-Item 'TestRegistry:\KeyWithChild\Child'
    New-Item 'TestRegistry:\KeyWithProperty'
    Set-ItemProperty 'TestRegistry:\KeyWithProperty' -Name 'SomeProperty' -Value 0

    Mock Remove-Item {}

    Context '[Registry key does not exist]' {
        RemoveRegistryKeyIfEmpty 'TestRegistry:\SomeKeyThatDoesNotExist'

        It 'Does not attempt to remove registry key' {
            Assert-MockCalled Remove-Item -Times 0
        }
    }

    Context '[Empty registry key]' {
        RemoveRegistryKeyIfEmpty 'TestRegistry:\Empty'

        It 'Removes registry key' {
            Assert-MockCalled Remove-Item -Times 1 -Exactly
            Assert-MockCalled Remove-Item -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq 'TestRegistry:\Empty'
                }
        }
    }

    Context '[Registry key with child item]' {
        RemoveRegistryKeyIfEmpty 'TestRegistry:\KeyWithChild'

        It 'Does not remove registry key' {
            Assert-MockCalled Remove-Item -Times 0
        }
    }

    Context '[Registry key with property]' {
        RemoveRegistryKeyIfEmpty 'TestRegistry:\KeyWithProperty'

        It 'Does not remove registry key' {
            Assert-MockCalled Remove-Item -Times 0
        }
    }
}