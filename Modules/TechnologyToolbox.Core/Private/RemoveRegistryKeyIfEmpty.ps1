Function RemoveRegistryKeyIfEmpty(
    [string] $registryPath) {
    Write-Verbose "Removing registry key ($registryPath) if empty..."

    If ((Test-Path $registryPath) -eq $false) {
        Write-Debug "Registry key ($registryPath) does not exist."

        return
    }

    $children = Get-ChildItem $registryPath

    If ($children -ne $null) {
        Write-Debug "The registry key has one or more children."

        return
    }

    $properties = Get-ItemProperty $registryPath

    If ($properties -ne $null) {
        Write-Debug "The registry key has one or more properties."

        return
    }

    Write-Verbose ("Removing registry key ($registryPath)...")

    Remove-Item $registryPath
}