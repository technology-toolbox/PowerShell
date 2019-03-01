. $PSScriptRoot\..\Private\GetBackConnectionHostNameList.ps1
. $PSScriptRoot\..\Private\SetBackConnectionHostNamesRegistryValue.ps1
. $PSScriptRoot\Add-BackConnectionHostNames.ps1

Describe 'Add-BackConnectionHostNames Tests' {
    [string] $registryPath =
        "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

    Context '[Registry key does not exist]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        Mock Get-Item {return $fakeRegistryKey}
        Mock New-ItemProperty {}

        Add-BackConnectionHostNames fabrikam-local

        It 'Reads expected registry key twice (once to retrieve property and again when saving)' {
            Assert-MockCalled Get-Item -Times 2 -Exactly
            Assert-MockCalled Get-Item -Times 2 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath
                }
        }

        It 'Creates BackConnectionHostNames registry key' {
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames' -and
                    $PropertyType -eq 'MultiString' -and
                    $Value -eq @('fabrikam-local')
                }
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

        Add-BackConnectionHostNames fabrikam-local

        It 'Sets BackConnectionHostNames registry key' {
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames' -and
                    $Value -eq @('fabrikam-local')
                }
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

        # HACK: Assert-MockCalled currently fails when ParameterFilter attempts
        # to match an array -- e.g. $Value -eq @('...', '...') -- so save the
        # value specified when calling the mock for subsequent validation
        $script:ValueSpecifiedToSetItemProperty = $null

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {$script:ValueSpecifiedToSetItemProperty = $Value}

        Add-BackConnectionHostNames fabrikam-local

        It 'Sets BackConnectionHostNames registry key' {
            $script:ValueSpecifiedToSetItemProperty |
                Should Be @('fabrikam-local', 'www-local.fabrikam.com')

            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
            Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames'
                }
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
        Mock Set-ItemProperty {}

        Add-BackConnectionHostNames fabrikam-local

        It 'Does not set BackConnectionHostNames registry key' {
            Assert-MockCalled Set-ItemProperty -Times 0
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

        Add-BackConnectionHostNames fabrikam-local

        It 'Does not set BackConnectionHostNames registry key' {
            Assert-MockCalled Set-ItemProperty -Times 0
        }
    }

    Context '[Hostnames specified in pipeline]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        # HACK: Assert-MockCalled currently fails when ParameterFilter attempts
        # to match an array -- e.g. $Value -eq @('...', '...') -- so save the
        # value specified when calling the mock for subsequent validation
        $script:ValueSpecifiedToNewItemProperty = $null

        Mock Get-Item {return $fakeRegistryKey}
        Mock New-ItemProperty {$script:ValueSpecifiedToNewItemProperty = $Value}

        'fabrikam-local', 'www-local.fabrikam.com' | Add-BackConnectionHostNames

        It 'Sets BackConnectionHostNames registry key' {
            $script:ValueSpecifiedToNewItemProperty |
                Should Be @('fabrikam-local', 'www-local.fabrikam.com')

            Assert-MockCalled New-ItemProperty -Times 1 -Exactly
            Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
                -ParameterFilter {
                    $Path -eq $registryPath -and
                    $Name -eq 'BackConnectionHostNames' -and
                    $PropertyType -eq 'MultiString'
                }
        }
    }
}