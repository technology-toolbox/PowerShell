. $PSScriptRoot\Get-ArpRetryCount.ps1

Describe 'Get-ArpRetryCount Tests' {
    [string] $tcpIpParametersPath =
        'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'

    Context '[ArpRetryCount not set]' {
        $errorMessage = 'Property ArpRetryCount does not exist at path' `
            + ' HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip' `
            + '\Parameters.'

        Mock Get-ItemProperty {throw $errorMessage}

        It 'Throws when ArpRetryCount property has not been set' {
            { Get-ArpRetryCount } | Should Throw $errorMessage
        }
    }

    Context '[ArpRetryCount previously set to 0]' {
        $fakeProperty = New-Object `
            -TypeName psobject `
            -Property @{
                'ArpRetryCount' = 0
            }

        Mock Get-ItemProperty {return $fakeProperty}

        It 'Returns expected value' {
            $result = Get-ArpRetryCount

            $result | Should Be 0
        }

        Assert-MockCalled Get-ItemProperty -Times 1 -Exactly
        Assert-MockCalled Get-ItemProperty -Times 1 -Exactly `
            -ParameterFilter {
                $Path -eq $tcpIpParametersPath -and
                $Name -eq 'ArpRetryCount'
            }
    }
}