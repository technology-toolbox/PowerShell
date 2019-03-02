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

            $zoneMappingInfo = GetInternetSecurityZoneMappingInfo -Pattern $pattern

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

            AddPatternToInternetSecurityZone $Zone $pattern
        }
    }
}