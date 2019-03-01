. $PSScriptRoot\CreateHostsEntryObject.ps1
. $PSScriptRoot\UpdateHostsFile.ps1

Describe 'UpdateHostsFile Tests' {
    [string] $hostsPath = `
        $env:WINDIR + '\System32\drivers\etc\hosts'

    Context '[Multiple entries for hosts file]' {
        Mock Set-Content {}

        $hostsEntries = @()

        $hostsEntries += (CreateHostsEntryObject -comment ' A comment')

        $hostsEntries += (CreateHostsEntryObject `
            -ipAddress 127.0.0.1 `
            -hostnames localhost)

        $hostsEntries += (CreateHostsEntryObject `
            -ipAddress 192.168.0.1 `
            -hostnames foo, bar `
            -comment ' Fictitious hosts')

        UpdateHostsFile $hostsEntries

        $expectedContent =
'# A comment' + [Environment]::NewLine `
+ '127.0.0.1	localhost' + [Environment]::NewLine `
+ '192.168.0.1	foo bar # Fictitious hosts'

        It 'Set hosts file content' {
            Assert-MockCalled Set-Content -Times 1 -Exactly
            Assert-MockCalled Set-Content -Times 1 -Exactly `
                -ParameterFilter {
                $Path -eq $hostsPath -and
                $Value -eq $expectedContent -and
                $Force -eq $true -and
                $Encoding -eq 'ASCII'
            }
        }
    }
}