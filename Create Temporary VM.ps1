[CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "High"
    )]

param(
    [Parameter(Mandatory=$true)]
    [string] $IsoPath,
    [long] $VhdSizeBytes = 32GB,
    [string] $VmRootPath = "C:\NotBackedUp\VMs",
    [long] $MemoryStartupBytes = 4GB,
    [string] $SwitchName = "Virtual LAN 2 - 192.168.10.x",
    [byte] $ProcessorCount = 2,
    [switch] $Force)

begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function Get-TimeStamp
    {
      Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    Function WriteElapsedTime(
        [System.Diagnostics.Stopwatch] $stopwatch =
            $(Throw "Value cannot be null: stopwatch"))
    {
        $timespan = $stopwatch.Elapsed

        $formattedTime = [string]::Format(
            "{0:00}:{1:00}:{2:00}",
            $timespan.Hours,
            $timespan.Minutes,
            $timespan.Seconds)

        Write-Host -Fore Cyan "(Elapsed time: $formattedTime)"
    }
}

process
{
    Write-Debug "IsoPath: $IsoPath"
    Write-Debug "VhdSizeBytes: $VhdSizeBytes"
    Write-Debug "VmRootPath: $VmRootPath"
    Write-Debug "MemoryStartupBytes: $MemoryStartupBytes"
    Write-Debug "SwitchName: $SwitchName"
    Write-Debug "ProcessorCount: $ProcessorCount"

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $vmName = [System.IO.Path]::GetRandomFileName().Split('.')[0].ToUpper()

    If ($Force -Or $PSCmdlet.ShouldProcess($env:COMPUTERNAME))
    {
        Write-Host "$(Get-TimeStamp): Creating VM ($vmName)..."

        New-VM `
	        -Name $vmName `
	        -Path $VmRootPath `
	        -MemoryStartupBytes $MemoryStartupBytes `
	        -SwitchName $SwitchName | Out-Null

        Set-VM -VMName $vmName -ProcessorCount $ProcessorCount

        New-Item -ItemType Directory "$VmRootPath\$vmName\Virtual Hard Disks" |
            Out-Null

        $vhdPath = "$VmRootPath\$vmName\Virtual Hard Disks\$vmName.vhdx"

        New-VHD -Path $vhdPath -SizeBytes $VhdSizeBytes | Out-Null

        Add-VMHardDiskDrive -VMName $vmName -Path $vhdPath

        Set-VMDvdDrive -VMName $vmName -Path $IsoPath

        Write-Host "$(Get-TimeStamp): Starting VM ($vmName)..."

        Start-VM $vmName

        Write-Warning "The VM ($vmName) will be deleted when it is powered off."

        $vm = Get-VM -Name $vmName

        While ($vm.State -ne "Off")
        {
            Write-Verbose "Temporary VM ($vmName) is running."
            Start-Sleep 5
        }

        $vhdActualSizeBytes = (Get-VHD $vhdPath).FileSize

        $vhdActualSizeGB = [Math]::Round($vhdActualSizeBytes / 1GB, 1)

        Write-Host "$(Get-TimeStamp): Final VHD size: $vhdActualSizeGB GB"

        Write-Host -NoNewLine `
            "$(Get-TimeStamp): Temporary VM ($vmName) lifespan: "

        WriteElapsedTime $stopwatch

        If ($Force -Or $PSCmdlet.ShouldContinue(
            "Confirm",
            "Delete VM ($VmRootPath\$vmName)?"))
        {
            Remove-VM -Name $vmName -Force
            Remove-Item -Recurse $VmRootPath\$vmName
        }
    }
}
