function Add-InternetSecurityZoneMapping {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium")]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("LocalIntranet", "TrustedSites", "RestrictedSites")]
        [string] $Zone,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Patterns)

    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

        Function AddPatternToInternetSecurityZone {
            [CmdletBinding(
                SupportsShouldProcess = $true,
                ConfirmImpact = "Medium")]
            Param(
                [ValidateSet("LocalIntranet", "TrustedSites", "RestrictedSites")]
                [string] $zone,
                [string] $pattern)

            Write-Verbose "Adding pattern ($pattern) to zone ($zone)..."

            [Uri] $url = [Uri] $pattern

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

            [string] $zoneMapPath = ("HKCU:\Software\Microsoft\Windows" `
                    + "\CurrentVersion\Internet Settings\ZoneMap")

            [string] $registryPath = $null

            If (IsEscEnabled -eq $true) {
                $registryPath = "$zoneMapPath\EscDomains\$domain"
            }
            Else {
                $registryPath = "$zoneMapPath\Domains\$domain"
            }

            If ((Test-Path $registryPath) -eq $false) {
                New-Item $registryPath | Out-Null
            }

            If ([string]::IsNullOrEmpty($subdomain) -eq $false) {
                $registryPath = $registryPath + "\$subdomain"

                If ((Test-Path $registryPath) -eq $false) {
                    New-Item $registryPath | Out-Null
                }
            }

            $registryKey = Get-Item $registryPath

            [string] $propertyName = $url.Scheme

            [int] $zoneIndex = -1

            switch ($zone) {
                "LocalIntranet" { $zoneIndex = 1 }
                "TrustedSites" { $zoneIndex = 2 }
                "RestrictedSites" { $zoneIndex = 4 }
                default { Throw "Unexpected zone ($zone)" }
            }

            $property = $registryKey.GetValue($propertyName, $null)

            If ($property -eq $null) {
                New-ItemProperty `
                    -Path $registryPath `
                    -Name $propertyName `
                    -PropertyType DWORD `
                    -Value $zoneIndex | Out-Null

                return
            }
            ElseIf ($property -eq $zoneIndex) {
                Write-Debug "The website is already in the $zone zone."

                return
            }

            # HACK: There's a bug when using the "-WhatIf" switch with the
            # Set-ItemProperty cmdlet -- specifically, when the path is not
            # created yet (due to the use of the "-WhatIf" switch).
            #
            # Reference:
            #
            #     http://powershell.com/cs/forums/t/23475.aspx
            #
            # To avoid showing an error in this scenario, mimic the behavior of
            # "Set-ItemProperty ... -WhatIf" by displaying the equivalent
            # message using Write-Host.
            If ($WhatIfPreference -and $WhatIfPreference.IsPresent -eq $true) {
                [string] $expandedRegistryPath = $registryPath.Replace(
                    "HKCU:",
                    "HKEY_CURRENT_USER")

                Write-Host `
                    ('What if: Performing operation "Set Property" on' `
                        + ' Target "Item: ' + $expandedRegistryPath `
                        + ' Property: ' + $propertyName + '".')
            }
            Else {
                Set-ItemProperty `
                    -Path $registryPath `
                    -Name $propertyName `
                    -Value $zoneIndex
            }
        }

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

        [bool] $isInputFromPipeline =
            ($PSBoundParameters.ContainsKey("Patterns") -eq $false)
    }

    Process {
        If ($isInputFromPipeline -eq $true) {
            $Patterns = $_
        }

        $Patterns | ForEach-Object {
            $pattern = $_

            AddPatternToInternetSecurityZone $Zone $pattern
        }
    }
}