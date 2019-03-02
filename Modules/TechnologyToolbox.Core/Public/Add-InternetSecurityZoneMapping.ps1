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