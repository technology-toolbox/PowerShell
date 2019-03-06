function GetUrlSecurityZoneMappingInfo {
    Param(
        [string] $Pattern
    )

    [Uri] $url = [Uri] $Pattern

    [string[]] $domainParts = $url.Host -split '\.'

    [string] $subdomain = $null
    [string] $domain = $null

    If ($domainParts.Length -eq 1) {
        $domain = $domainParts[0]
    }
    ElseIf ($domainParts.Length -eq 2) {
        $domain = $domainParts[0..1] -join '.'
    }
    Else {
        $domainStartIndex = $domainParts.Length - 2
        $domainEndIndex = $domainStartIndex + 1

        $subdomainStartIndex = 0
        $subdomainEndIndex = $domainStartIndex - 1

        $subdomain = `
            $domainParts[$subdomainStartIndex..$subdomainEndIndex] `
            -join '.'

        $domain = $domainParts[$domainStartIndex..$domainEndIndex] `
            -join '.'
    }

    Write-Debug "subdomain: $subdomain"
    Write-Debug "domain: $domain"

    [string] $zoneMapPath = GetUrlSecurityZoneMapPath

    [string] $registryPath = $null

    If (IsEscEnabled -eq $true) {
        $registryPath = "$zoneMapPath\EscDomains\$domain"
    }
    Else {
        $registryPath = "$zoneMapPath\Domains\$domain"
    }

    If ([string]::IsNullOrEmpty($subdomain) -eq $false) {
        $registryPath = $registryPath + "\$subdomain"
    }

    $properties = @{
        Scheme       = $url.Scheme
        Domain       = $domain
        Subdomain    = $subdomain
        RegistryPath = $registryPath
    }

    New-Object `
        -TypeName PSObject `
        -Property $properties
}