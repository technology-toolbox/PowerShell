. $PSScriptRoot\Get-BackConnectionHostNames.ps1

Describe 'Get-BackConnectionHostNames Tests' {
    [string] $registryPath =
        "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

    Context '[BackConnectionHostNames registry key does not exist]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        Mock Get-Item {return $fakeRegistryKey}

        $result = Get-BackConnectionHostNames

        It 'Reads expected registry key' {
            Assert-MockCalled Get-Item -Times 1 -Exactly
            Assert-MockCalled Get-Item -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath
                }
        }

        It 'Returns null when BackConnectionHostNames registry key does not exist' {
            $result | Should Be $null
        }
    }

    Context '[Empty BackConnectionHostNames registry key]' {
        [string[]] $backConnectionHostNames = @('')

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return $backConnectionHostNames
        }

        Mock Get-Item {return $fakeRegistryKey}

        $result = Get-BackConnectionHostNames

        It 'Returns expected value' {
            $result | Should Be $backConnectionHostNames
        }
    }

    Context '[BackConnectionHostNames registry key with single item]' {
        [string[]] $backConnectionHostNames = @('fabrikam-local')

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return $backConnectionHostNames
        }

        Mock Get-Item {return $fakeRegistryKey}

        $result = Get-BackConnectionHostNames

        It 'Returns expected value' {
            $result | Should Be 'fabrikam-local'
        }
    }

    Context '[BackConnectionHostNames registry key with multiple items]' {
        [string[]] $backConnectionHostNames = @(
            'fabrikam-local',
            'www-local.fabrikam.com'
        )

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return $backConnectionHostNames
        }

        Mock Get-Item {return $fakeRegistryKey}

        $result = Get-BackConnectionHostNames

        It 'Returns expected values' {
            $result | Should Be $backConnectionHostNames
        }
    }
}