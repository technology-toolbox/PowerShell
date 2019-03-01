function ParseHostsEntry(
    [string] $line) {
    $hostsEntry = CreateHostsEntryObject

    Write-Debug "Parsing hosts entry: $line"

    If ($line.Contains("#") -eq $true) {
        If ($line -eq "#") {
            $hostsEntry.Comment = [string]::Empty
        }
        Else {
            $hostsEntry.Comment = $line.Substring($line.IndexOf("#") + 1)
        }

        $line = $line.Substring(0, $line.IndexOf("#"))
    }

    $line = $line.Trim()

    If ($line.Length -gt 0) {
        $hostsEntry.IpAddress = ($line -Split "\s+")[0]

        Write-Debug "Parsed address: $($hostsEntry.IpAddress)"

        [string[]] $parsedHostnames = $line.Substring(
            $hostsEntry.IpAddress.Length + 1).Trim() -Split "\s+"

        Write-Debug ("Parsed hostnames ($($parsedHostnames.Length)):" `
                + " $parsedHostnames")

        $parsedHostnames | foreach {
            $hostsEntry.Hostnames.Add($_) | Out-Null
        }
    }

    return $hostsEntry
}