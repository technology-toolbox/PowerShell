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

            $zoneMappingInfo = GetInternetSecurityZoneMappingInfo -Pattern $pattern

            [string] $registryPath = $zoneMappingInfo.RegistryPath

            [string] $domainRegistryPath = $registryPath

            If ([string]::IsNullOrEmpty($zoneMappingInfo.Subdomain) -eq $false) {
                $domainRegistryPath = Split-Path $registryPath -Parent
            }
            Else {
                $domainRegistryPath = $registryPath
            }

            If ((Test-Path $domainRegistryPath) -eq $false) {
                Write-Debug "Registry key ($domainRegistryPath) does not exist."

                return
            }

            If ([string]::IsNullOrEmpty($zoneMappingInfo.Subdomain) -eq $false) {
                If ((Test-Path $registryPath) -eq $false) {
                    Write-Debug "Registry key ($registryPath) does not exist."

                    return
                }
            }

            $registryKey = Get-Item $registryPath

            [string] $propertyName = $zoneMappingInfo.Scheme

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