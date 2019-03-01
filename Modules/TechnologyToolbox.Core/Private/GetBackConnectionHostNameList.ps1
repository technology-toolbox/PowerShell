function GetBackConnectionHostNameList {
    [Collections.ArrayList] $hostNameList = New-Object Collections.ArrayList

    [string] $registryPath =
        "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0"

    $registryKey = Get-Item -Path $registryPath

    $registryValue = $registryKey.GetValue("BackConnectionHostNames")

    $registryValue | ForEach-Object {
        $hostNameList.Add($_) | Out-Null
    }

    # HACK: Return an array (containing the ArrayList) to avoid issue with
    # PowerShell returning a string (when registry value only contains one
    # item)
    return , $hostNameList
}