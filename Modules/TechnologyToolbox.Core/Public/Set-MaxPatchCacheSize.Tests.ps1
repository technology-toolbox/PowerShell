. $PSScriptRoot\Set-MaxPatchCacheSize.ps1

Describe 'Set-MaxPatchCacheSize Tests' {
    [string] $installerRegistryPath = `
        'HKLM:\Software\Policies\Microsoft\Windows\Installer'

    Context '[Installer registry key does not exist]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        Mock Get-Item {return $null}
        Mock New-Item {return $fakeRegistryKey}
        Mock New-ItemProperty {return $fakeRegistryKey}

        It 'Creates the Installer and MaxPatchCacheSize registry keys' {
            Set-MaxPatchCacheSize -MaxPercentageOfDiskSpace 10
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly
        Assert-MockCalled New-Item -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $installerRegistryPath
            }

        Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $installerRegistryPath -and
                $Name -eq 'MaxPatchCacheSize' -and
                $PropertyType -eq 'DWord' -and
                $Value -eq 10
            }
    }

    Context '[Installer registry key exists but MaxPatchCacheSize not set]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        Mock Get-Item {return $fakeRegistryKey}
        Mock New-ItemProperty {return $fakeRegistryKey}

        It 'Creates the MaxPatchCacheSize registry key' {
            Set-MaxPatchCacheSize -MaxPercentageOfDiskSpace 10
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly

        Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $installerRegistryPath -and
                $Name -eq 'MaxPatchCacheSize' -and
                $PropertyType -eq 'DWord' -and
                $Value -eq 10
            }
    }

    Context '[MaxPatchCacheSize previously set to 0]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                MaxPatchCacheSize = 0
            }

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {return 0}

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {return $fakeRegistryKey}

        It 'Sets registry key to expected value' {
            Set-MaxPatchCacheSize -MaxPercentageOfDiskSpace 10
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly
        Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $installerRegistryPath -and
                $Name -eq 'MaxPatchCacheSize' -and
                $Value -eq 10
            }
    }

    Context '[MaxPatchCacheSize previously set to specified value]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
                MaxPatchCacheSize = 10
            }

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return 10
        }

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {}

        It 'Does nothing when registry key set to expected value' {
            Set-MaxPatchCacheSize -MaxPercentageOfDiskSpace 10
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly
        Assert-MockCalled Set-ItemProperty -Times 0 -Exactly
    }
}