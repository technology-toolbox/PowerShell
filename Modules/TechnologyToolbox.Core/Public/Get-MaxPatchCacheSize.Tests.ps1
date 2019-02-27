. $PSScriptRoot\Get-MaxPatchCacheSize.ps1

Describe 'Get-MaxPatchCacheSize Tests' {
    [string] $installerRegistryPath = `
        'HKLM:\Software\Policies\Microsoft\Windows\Installer'

    Context '[Installer registry key does not exist]' {
        $errorMessage = 'Cannot find path' `
            + " '$installerRegistryPath'" `
            + ' because it does not exist.'

        Mock Get-ItemProperty {throw $errorMessage}

        It 'Throws when Installer registry key does not exist' {
            { Get-MaxPatchCacheSize } | Should Throw $errorMessage
        }
    }

    Context '[MaxPatchCacheSize not set]' {
        $errorMessage = 'Property MaxPatchCacheSize does not exist at path' `
            + ' HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows' `
            + '\Installer.'

        Mock Get-ItemProperty {throw $errorMessage}

        It 'Throws when MaxPatchCacheSize property has not been set' {
            { Get-MaxPatchCacheSize } | Should Throw $errorMessage
        }
    }

    Context '[MaxPatchCacheSize previously set to 0]' {
        $fakeProperty = New-Object `
            -TypeName psobject `
            -Property @{
                'MaxPatchCacheSize' = 0
            }

        Mock Get-ItemProperty {return $fakeProperty}

        It 'Returns expected value' {
            $result = Get-MaxPatchCacheSize

            $result | Should Be 0
        }

        Assert-MockCalled Get-ItemProperty -Times 1 -Exactly
        Assert-MockCalled Get-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $installerRegistryPath -and
                $Name -eq 'MaxPatchCacheSize'
            }
    }
}