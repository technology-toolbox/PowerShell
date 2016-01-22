[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact="High")]
Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string] $VMHost,
    [Parameter(Mandatory = $True, Position = 1)]
    [string] $VMName,
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
    If ($PSCmdlet.ShouldProcess($VMName) -eq $True)
    {
        [string] $activity = "Update virtual machine baseline ($VMName)"

        StartActivity $activity

        $vm = Get-VM -Name $VMName -ComputerName $VMHost

        If ($StopVMFirst -eq $true)
        {
            If ($vm.State -ne "Off")
            {
                UpdateProgress `
                    -Activity $activity `
                    -Status "Stopping virtual machine ($VMName)..."

                Stop-VM -Name $VMName -ComputerName $VMHost
            }
        }
    
	    $snapshot = Get-VMSnapshot -ComputerName $VMHost -VMName $VMName |
            Sort-Object CreationTime |
            Select-Object -Last 1

	    If ($snapshot)
	    {
		    $snapshotName = $snapshot.Name
		
	        UpdateProgress `
                -Activity $activity `
                -Status ("Removing checkpoint ($snapshotName) for virtual" `
                    + " machine ($VMName)...")

	        Remove-VMSnapshot `
                -VMName $VMName `
                -Name $snapshotName `
                -ComputerName $VMHost
	
	        UpdateProgress `
                -Activity $activity `
                -Status "Waiting a few seconds for merge to start..."

	        Start-Sleep -Seconds 5
	
	        UpdateProgress `
                -Activity $activity `
                -Status ("Waiting for merge to complete on virtual machine" `
                    + " ($VMName)...")

	        while (Get-VM -Name $VMName -ComputerName $VMHost |
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
                + " ($VMName)...")

        Checkpoint-VM `
            -Name $VMName `
            -SnapshotName $snapshotName `
            -ComputerName $VMHost

        UpdateProgress `
            -Activity $activity `
            -Status "Successfully updated virtual machine baseline ($VMName)" `
            -Completed
    }
}