# Returns $true if Internet Explorer Enhanced Security Configuration is
# enabled; otherwise $false
Function IsEscEnabled() {
    Write-Verbose `
        "Checking if Enhanced Security Configuration is enabled..."

    [bool] $isEscEnabled = $false

    [string] $registryPath = "HKLM:\SOFTWARE\Microsoft\Active Setup" `
        + "\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

    If ((Test-Path $registryPath) -eq $false) {
        Write-Debug "Registry key ($registryPath) does not exist."
    }
    Else {
        $properties = Get-ItemProperty $registryPath

        If ($properties -eq $null) {
            Write-Debug ("No properties found in registry key" `
                    + " ($registryPath).")
        }
        Else {
            $isEscEnabled = ($properties.IsInstalled -eq 1)
        }
    }

    If ($isEscEnabled -eq $true) {
        Write-Debug "Enhanced Security Configuration is enabled."
    }
    Else {
        Write-Debug "Enhanced Security Configuration is not enabled."
    }

    return $isEscEnabled
}