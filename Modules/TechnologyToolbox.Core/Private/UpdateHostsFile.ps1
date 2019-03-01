function UpdateHostsFile(
    $hostsEntries = $(Throw "Value cannot be null: hostsEntries")) {
    Write-Verbose "Updatings hosts file..."

    [string] $hostsFile = $env:WINDIR + "\System32\drivers\etc\hosts"

    $buffer = New-Object System.Text.StringBuilder

    $hostsEntries | foreach {

        If ([string]::IsNullOrEmpty($_.IpAddress) -eq $false) {
            $buffer.Append($_.IpAddress) | Out-Null
            $buffer.Append("`t") | Out-Null
        }

        If ($_.Hostnames -ne $null) {
            [bool] $firstHostname = $true

            $_.Hostnames | foreach {
                If ($firstHostname -eq $false) {
                    $buffer.Append(" ") | Out-Null
                }
                Else {
                    $firstHostname = $false
                }

                $buffer.Append($_) | Out-Null
            }
        }

        If ($_.Comment -ne $null) {
            If ([string]::IsNullOrEmpty($_.IpAddress) -eq $false) {
                $buffer.Append(" ") | Out-Null
            }

            $buffer.Append("#") | Out-Null
            $buffer.Append($_.Comment) | Out-Null
        }

        $buffer.Append([System.Environment]::NewLine) | Out-Null
    }

    [string] $hostsContent = $buffer.ToString()

    $hostsContent = $hostsContent.Trim()

    Set-Content -Path $hostsFile -Value $hostsContent -Force -Encoding ASCII

    Write-Verbose "Successfully updated hosts file."
}