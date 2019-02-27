. $PSScriptRoot\Set-ArpRetryCount.ps1

Describe 'Set-ArpRetryCount Tests' {
    [string] $tcpIpParametersPath =
    'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'

    Context '[ArpRetryCount not set]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{}

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {}

        Mock Get-Item {return $fakeRegistryKey}
        Mock New-ItemProperty {return $fakeRegistryKey}

        It 'Creates the ArpRetryCount registry key' {
            Set-ArpRetryCount -ArpRetryCount 2
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly
        Assert-MockCalled Get-Item -Times 1 -Exactly `
            -ParameterFilter { $Path -eq $tcpIpParametersPath }

        Assert-MockCalled New-ItemProperty -Times 1 -Exactly
        Assert-MockCalled New-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $tcpIpParametersPath -and
                $Name -eq 'ArpRetryCount' -and
                $PropertyType -eq 'DWord' -and
                $Value -eq 2
            }
    }

    Context '[ArpRetryCount previously set to 0]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            ArpRetryCount = 0
        }

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {return 0}

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {return $fakeRegistryKey}

        It 'Sets registry key to expected value' {
            Set-ArpRetryCount -ArpRetryCount 2
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly
        Assert-MockCalled Get-Item -Times 1 -Exactly `
            -ParameterFilter { $Path -eq $tcpIpParametersPath }

        Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
        Assert-MockCalled Set-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
            $Path -eq $tcpIpParametersPath -and
            $Name -eq 'ArpRetryCount' -and
            $Value -eq 2
        }
    }

    Context '[ArpRetryCount previously set to specified value]' {
        $fakeRegistryKey = New-Object `
            -TypeName psobject `
            -Property @{
            ArpRetryCount = 0
        }

        $fakeRegistryKey | Add-Member ScriptMethod GetValue {
            return 0
        }

        Mock Get-Item {return $fakeRegistryKey}
        Mock Set-ItemProperty {}

        It 'Does nothing when registry key set to expected value' {
            Set-ArpRetryCount -ArpRetryCount 0
        }

        Assert-MockCalled Get-Item -Times 1 -Exactly
        Assert-MockCalled Get-Item -Times 1 -Exactly `
            -ParameterFilter { $Path -eq $tcpIpParametersPath }

        Assert-MockCalled Set-ItemProperty -Times 0 -Exactly
    }
}