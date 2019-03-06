. $PSScriptRoot\GetUrlSecurityZoneMapPath.ps1

Describe 'GetUrlSecurityZoneMapPath Tests' {
    It 'Returns expected value' {
        GetUrlSecurityZoneMapPath |
            Should Be ('HKCU:\Software\Microsoft\Windows' `
                + '\CurrentVersion\Internet Settings\ZoneMap')
    }
}