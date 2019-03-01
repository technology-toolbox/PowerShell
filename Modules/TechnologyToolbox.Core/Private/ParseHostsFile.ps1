function ParseHostsFile {
    $hostsEntries = New-Object System.Collections.ArrayList

    [string] $hostsFile = $env:WINDIR + "\System32\drivers\etc\hosts"

    If ((Test-Path $hostsFile) -eq $false) {
        Write-Verbose "Hosts file does not exist."
    }
    Else {
        [string[]] $hostsContent = Get-Content $hostsFile

        $hostsContent | foreach {
            $hostsEntry = ParseHostsEntry $_

            $hostsEntries.Add($hostsEntry) | Out-Null
        }
    }

    # HACK: Return an array (containing the ArrayList) to avoid issue with
    # PowerShell returning $null (when hosts file does not exist)
    return , $hostsEntries
}