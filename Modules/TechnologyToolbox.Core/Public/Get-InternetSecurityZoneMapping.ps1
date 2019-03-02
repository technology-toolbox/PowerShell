<#
.SYNOPSIS
Gets the URL patterns mapped to various security zones.

.DESCRIPTION
The Get-InternetSecurityZoneMapping cmdlet gets the complete set of patterns
mapped to a security zone.

Without parameters, Get-InternetSecurityZoneMapping gets all of the zone
mappings for the current user. You can also specify a particular zone.

Get-InternetSecurityZoneMapping returns objects that have Zone and Pattern
properties.

.PARAMETER Zone
Optional parameter that specifies the zone to get the mappings for.

.EXAMPLE
.\Get-InternetSecurityZoneMapping.ps1

Zone            Pattern
----            -------
LocalIntranet   http://foobar
LocalIntranet   money://@surf.mar@
TrustedSites    http://*.windowsupdate.microsoft.com
TrustedSites    https://*.windowsupdate.microsoft.com

.EXAMPLE
.\Get-InternetSecurityZoneMapping.ps1 -Zone LocalIntranet

Zone            Pattern
----            -------
LocalIntranet   http://foobar
LocalIntranet   money://@surf.mar@

#>
function Get-InternetSecurityZoneMapping {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [ValidateSet("LocalMachine", "LocalIntranet", "TrustedSites", "Internet",
            "RestrictedSites")]
        [string] $Zone)

    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"

        Function CreateZoneMappingObject(
            [string] $zone,
            [string] $pattern) {
            $zoneMapping = New-Object PSObject
            $zoneMapping | Add-Member NoteProperty -Name "Zone" -Value $zone
            $zoneMapping |
                Add-Member NoteProperty -Name "Pattern" -Value $pattern

            return $zoneMapping
        }

        Function GetZoneMappings(
            [string] $zoneFilter) {
            Write-Verbose "Getting zone mappings..."

            Write-Debug "zoneFilter: $zoneFilter"

            [string] $zoneMapPath = ("HKCU:\Software\Microsoft\Windows" `
                    + "\CurrentVersion\Internet Settings\ZoneMap")

            [string] $registryPath = $null

            If (IsEscEnabled -eq $true) {
                $registryPath = "$zoneMapPath\EscDomains"
            }
            Else {
                $registryPath = "$zoneMapPath\Domains"
            }

            Get-ChildItem -Path $registryPath | ForEach-Object {
                $domainRegistryKey = $_

                GetZoneMappingsFromRegistryKey `
                    $zoneFilter $domainRegistryKey $false

                Get-ChildItem -Path $domainRegistryKey.PSPath | ForEach-Object {
                    $subdomainRegistryKey = $_

                    GetZoneMappingsFromRegistryKey `
                        $zoneFilter $subdomainRegistryKey $true
                }
            }
        }

        Function GetZoneMappingsFromRegistryKey(
            [string] $zoneFilter,
            $registryKey,
            [bool] $isSubdomain) {
            Write-Verbose "Getting zone mappings from registry key ($registryKey)..."

            $schemeNames = $registryKey.GetValueNames()

            Write-Debug "schemeNames: $schemeNames"

            $schemeNames | ForEach-Object {
                $schemeName = $_

                If ([string]::IsNullOrEmpty($schemeName) -eq $true) {
                    return
                }

                $property = Get-ItemProperty $registryKey.PSPath `
                    -Name $schemeName

                $zoneIndex = $property |
                    Select-Object -ExpandProperty $schemeName

                switch ($zoneIndex) {
                    0 { $zone = "LocalMachine" }
                    1 { $zone = "LocalIntranet" }
                    2 { $zone = "TrustedSites" }
                    3 { $zone = "Internet" }
                    4 { $zone = "RestrictedSites" }
                    default { Throw "Unexpected zone index ($zoneIndex)" }
                }

                $pattern = $property |
                    Select-Object -ExpandProperty PSChildName

                $pattern = $schemeName + "://" + $pattern

                If ($isSubdomain -eq $true) {
                    $delimiterPos = $registryKey.PSParentPath.LastIndexOf('\')

                    $domain = $registryKey.PSParentPath.Substring(
                        $delimiterPos + 1)

                    $pattern = $pattern + "." + $domain
                }

                If ([string]::IsNullOrEmpty($zoneFilter) -eq $true `
                        -or $zone -eq $zoneFilter) {
                    $zoneMapping = CreateZoneMappingObject $zone $pattern

                    $zoneMapping
                }
                Else {
                    Write-Verbose ("Ignoring zone mapping ($pattern) because" `
                            + " the zone ($zone) does not match the specified" `
                            + " filter ($zoneFilter).")
                }
            }
        }
    }

    Process {
        GetZoneMappings $Zone
    }
}