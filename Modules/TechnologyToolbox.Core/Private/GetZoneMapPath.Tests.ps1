. $PSScriptRoot\GetZoneMapPath.ps1

Describe 'GetZoneMapPath Tests' {
    It 'Returns expected value' {
        GetZoneMapPath |
            Should Be ('HKCU:\Software\Microsoft\Windows' `
                + '\CurrentVersion\Internet Settings\ZoneMap')
    }
}