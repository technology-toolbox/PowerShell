<#
.SYNOPSIS
Adds one or more patterns to the specified URL security zone for the current
user.

.DESCRIPTION
URL security zones group URL namespaces according to their respective levels of
trust. URL patterns can be added to the Local Intranet Zone, Trusted Sites
Zone, and Restricted Sites Zone.

.LINK
https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/ms537183(v=vs.85)

.PARAMETER Zone
Specifies the URL security zone ("LocalIntranet", "TrustedSites" or
"RestrictedSites") to add the patterns to.

.PARAMETER Patterns
Specifies the URL patterns to add the zone mappings for.

.EXAMPLE
.\Add-UrlSecurityZoneMapping.ps1 -Zone LocalIntranet -Patterns http://localhost

Adds the "http" scheme for the "localhost" domain to the Local Intranet Zone.

.EXAMPLE
.\Add-UrlSecurityZoneMapping.ps1 TrustedSites https://fabrikam.com

Adds the "https" scheme for the "fabrikam.com" domain to the Trusted Sites Zone.

.EXAMPLE
.\Add-UrlSecurityZoneMapping.ps1 TrustedSites http://www.fabrikam.com, https://www.fabrikam.com

Adds the "http" and "https" schemes for the "www.fabrikam.com" subdomain to the
Trusted Sites Zone.
#>
function Add-UrlSecurityZoneMapping {
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

        Function AddPatternToUrlSecurityZone {
            [CmdletBinding(
                SupportsShouldProcess = $true,
                ConfirmImpact = "Medium")]
            Param(
                [ValidateSet("LocalIntranet", "TrustedSites", "RestrictedSites")]
                [string] $zone,
                [string] $pattern)

            Write-Verbose "Adding pattern ($pattern) to zone ($zone)..."

            $zoneMappingInfo = GetUrlSecurityZoneMappingInfo -Pattern $pattern

            [string] $registryPath = $zoneMappingInfo.RegistryPath

            If ((Test-Path $registryPath) -eq $false) {
                If ([string]::IsNullOrEmpty($zoneMappingInfo.Subdomain) -eq $false) {
                    [string] $parentRegistryPath = Split-Path $registryPath -Parent

                    If ((Test-Path $parentRegistryPath) -eq $false) {
                        New-Item $parentRegistryPath | Out-Null
                    }
                }

                New-Item $registryPath | Out-Null
            }

            $registryKey = Get-Item $registryPath

            [string] $propertyName = $zoneMappingInfo.Scheme

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

                Write-Host ('What if: Performing operation "Set Property" on' `
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

        [bool] $isInputFromPipeline =
        ($PSBoundParameters.ContainsKey("Patterns") -eq $false)
    }

    Process {
        If ($isInputFromPipeline -eq $true) {
            $Patterns = $_
        }

        $Patterns | ForEach-Object {
            $pattern = $_

            AddPatternToUrlSecurityZone $Zone $pattern
        }
    }
}