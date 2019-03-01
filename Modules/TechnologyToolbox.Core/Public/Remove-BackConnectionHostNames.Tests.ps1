. $PSScriptRoot\Remove-BackConnectionHostNames.ps1

Describe 'Remove-BackConnectionHostNames Tests' {
    [string] $registryPath =
        "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

    Context '[Registry key does not exist]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {}

        Remove-BackConnectionHostNames fabrikam-local

        It 'Reads expected registry key' {
            Assert-MockCalled Get-Item -Times 1 -Exactly
            Assert-MockCalled Get-Item -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath
                }
        }

        It 'Does not set BackConnectionHostNames property' {
            Assert-MockCalled Set-ItemProperty -Times 0 -Exactly
        }
    }

    Context '[Registry key is empty]' {
        [string[]] $backConnectionHostNames = @('')

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return $backConnectionHostNames
        }

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {}

        Remove-BackConnectionHostNames fabrikam-local

        It 'Does not set BackConnectionHostNames property' {
            Assert-MockCalled Set-ItemProperty -Times 0 -Exactly
        }
    }

    Context '[Registry key does not contain specified hostname]' {
        [string[]] $backConnectionHostNames = @('www-local.fabrikam.com')

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return $backConnectionHostNames
        }

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {}

        Remove-BackConnectionHostNames fabrikam-local

        It 'Does not set BackConnectionHostNames property' {
            Assert-MockCalled Set-ItemProperty -Times 0 -Exactly
        }
    }

    Context '[Registry key contains specified hostname]' {
        [string[]] $backConnectionHostNames = @('fabrikam-local')

        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return $backConnectionHostNames
        }

        Mock Get-Item {return $fakeRegistryKey}
        Mock Remove-ItemProperty {}

        Remove-BackConnectionHostNames fabrikam-local

        It 'Removes BackConnectionHostNames registry key' {
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames'
                }
        }
    }

    Context '[Registry key contains specified hostname and other items]' {
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
        Mock Set-ItemProperty {}

        Remove-BackConnectionHostNames fabrikam-local

        It 'Sets BackConnectionHostNames registry key' {
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames' -and
                    $Value -eq @('www-local.fabrikam.com')
                }
        }
    }

    Context '[Registry key contains specified hostnames in pipeline]' {
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
        Mock Remove-ItemProperty {}

        'fabrikam-local', 'www-local.fabrikam.com' |
            Remove-BackConnectionHostNames

        It 'Removes BackConnectionHostNames registry key' {
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Remove-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames'
                }
        }
    }
}