function CreateHostsEntryObject(
    [string] $ipAddress,
    [string[]] $hostnames,
    <# [string] #> $comment) { #HACK: never $null if type is specified
    $hostsEntry = New-Object PSObject
    $hostsEntry | Add-Member NoteProperty -Name "IpAddress" `
        -Value $ipAddress

    [System.Collections.ArrayList] $hostnamesList =
        New-Object System.Collections.ArrayList

    $hostsEntry | Add-Member NoteProperty -Name "Hostnames" `
        -Value $hostnamesList

    If ($hostnames -ne $null) {
        $hostnames | foreach {
            $hostsEntry.Hostnames.Add($_) | Out-Null
        }
    }

    $hostsEntry | Add-Member NoteProperty -Name "Comment" -Value $comment

    return $hostsEntry
}