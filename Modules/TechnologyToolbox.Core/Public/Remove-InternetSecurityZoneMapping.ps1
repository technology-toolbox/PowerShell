function Remove-InternetSecurityZoneMapping {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Medium")]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Patterns)

    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

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

        Function RemovePatternFromInternetSecurityZone {
            [CmdletBinding(
                SupportsShouldProcess = $true,
                ConfirmImpact = "Medium")]
            Param(
                [string] $pattern)

            Write-Verbose `
                "Removing security zone mapping for pattern ($pattern)..."

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

            [string] $zoneMapPath = "HKCU:\Software\Microsoft\Windows" `
                + "\CurrentVersion\Internet Settings\ZoneMap"

            [string] $registryPath = $null

            If (IsEscEnabled -eq $true) {
                $registryPath = "$zoneMapPath\EscDomains\$domain"
            }
            Else {
                $registryPath = "$zoneMapPath\Domains\$domain"
            }

            If ((Test-Path $registryPath) -eq $false) {
                Write-Debug "Registry key ($registryPath) does not exist."

                return
            }

            [string] $domainRegistryPath = $registryPath

            If ([string]::IsNullOrEmpty($subdomain) -eq $false) {
                $registryPath = $registryPath + "\$subdomain"

                If ((Test-Path $registryPath) -eq $false) {
                    Write-Debug "Registry key ($registryPath) does not exist."

                    return
                }
            }

            $registryKey = Get-Item $registryPath

            [string] $propertyName = $url.Scheme

            $property = $registryKey.GetValue($propertyName, $null)

            If ($property -eq $null) {
                Write-Debug "Property ($propertyName) does not exist."
            }
            Else {
                # HACK: There's a bug when using the "-WhatIf" switch with the
                # Remove-ItemProperty cmdlet.
                #
                # Reference:
                #
                #     http://www.vistax64.com/powershell/31469-remove-itemproperty-whatif-bug.html
                #
                # To avoid showing an error in this scenario, mimic the
                #  behavior of "Remove-ItemProperty ... -WhatIf" by displaying
                # the equivalent message using Write-Host.
                If ($WhatIfPreference -and $WhatIfPreference.IsPresent -eq $true) {
                    [string] $expandedRegistryPath = $registryPath.Replace(
                        "HKCU:",
                        "HKEY_CURRENT_USER")

                    Write-Host `
                    ('What if: Performing operation "Remove Property" on' `
                            + ' Target "Item: ' + $expandedRegistryPath `
                            + ' Property: ' + $propertyName + '".')
                }
                Else {
                    Write-Verbose ("Removing item property ($propertyName) from " `
                            + " registry key ($registryPath)...")

                    Remove-ItemProperty -Path $registryPath -Name $propertyName
                }
            }

            RemoveRegistryKeyIfEmpty $registryPath
            RemoveRegistryKeyIfEmpty $domainRegistryPath
        }

        # Returns $true if Internet Explorer Enhanced Security Configuration is
        # enabled; otherwise $false
        Function IsEscEnabled() {
            Write-Verbose "Checking if Enhanced Security Configuration is enabled..."

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

            RemovePatternFromInternetSecurityZone $pattern
        }
    }
}