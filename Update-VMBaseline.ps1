[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact="High")]
Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string] $Name,
    [string] $ComputerName = $env:COMPUTERNAME,
    [bool] $StopVMFirst = $True)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function StartActivity(
        [string] $Activity)
    {
        Write-Verbose "Start activity: $Activity"

        Write-Progress `
            -Activity $Activity `
            -Status "Started"
    }

    Function UpdateProgress(
        [string] $Activity,
        [string] $Status,
        [switch] $Completed)
    {
        Write-Verbose "Status: $Status"

        Write-Progress `
            -Activity $Activity `
            -Status $Status `
            -Completed:([bool]::Parse($Completed))
    }
}

Process
{
    If ($PSCmdlet.ShouldProcess($Name) -eq $True)
    {
        [string] $activity = "Update virtual machine baseline ($Name)"

        StartActivity $activity

        $vm = Get-VM -Name $Name -ComputerName $ComputerName

        If ($StopVMFirst -eq $true)
        {
            If ($vm.State -ne "Off")
            {
                UpdateProgress `
                    -Activity $activity `
                    -Status "Stopping virtual machine ($Name)..."

                Stop-VM -Name $Name -ComputerName $ComputerName
            }
        }
    
        $snapshot = Get-VMSnapshot -ComputerName $ComputerName -VMName $Name |
            Sort-Object CreationTime |
            Select-Object -Last 1

        If ($snapshot)
        {
            $snapshotName = $snapshot.Name
        
            UpdateProgress `
                -Activity $activity `
                -Status ("Removing checkpoint ($snapshotName) for virtual" `
                    + " machine ($Name)...")

            Remove-VMSnapshot `
                -VMName $Name `
                -Name $snapshotName `
                -ComputerName $ComputerName

            UpdateProgress `
                -Activity $activity `
                -Status "Waiting a few seconds for merge to start..."

            Start-Sleep -Seconds 5
    
            UpdateProgress `
                -Activity $activity `
                -Status ("Waiting for merge to complete on virtual machine" `
                    + " ($Name)...")

            while (Get-VM -Name $Name -ComputerName $ComputerName |
                Where Status -eq "Merging disks")
                {
                    Start-Sleep -Seconds 10
                }
        }
        Else
        {
            $snapshotName = "Baseline"
        }
    
        UpdateProgress `
            -Activity $activity `
            -Status ("Creating checkpoint ($snapshotName) for virtual machine" `
                + " ($Name)...")

        Checkpoint-VM `
            -Name $Name `
            -SnapshotName $snapshotName `
            -ComputerName $ComputerName    

        UpdateProgress `
            -Activity $activity `
            -Status "Successfully updated virtual machine baseline ($Name)" `
            -Completed
    }
}
