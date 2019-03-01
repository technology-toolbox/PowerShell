function SetBackConnectionHostNamesRegistryValue(
    [Collections.ArrayList] $hostNameList =
    $(Throw "Value cannot be null: hostNameList")) {
    $hostNameList.Sort()

    for ([int] $i = 0; $i -lt $hostNameList.Count; $i++) {
        If ([string]::IsNullOrEmpty($hostNameList[$i]) -eq $true) {
            $hostNameList.RemoveAt($i)
            $i--
        }
    }

    [string] $registryPath =
    "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

    $registryKey = Get-Item -Path $registryPath

    $registryValue = $registryKey.GetValue("BackConnectionHostNames")

    If ($hostNameList.Count -eq 0) {
        Remove-ItemProperty -Path $registryPath `
            -Name BackConnectionHostNames
    }
    ElseIf ($registryValue -eq $null) {
        New-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
            -PropertyType MultiString -Value $hostNameList | Out-Null
    }
    Else {
        Set-ItemProperty -Path $registryPath -Name BackConnectionHostNames `
            -Value $hostNameList | Out-Null
    }
}