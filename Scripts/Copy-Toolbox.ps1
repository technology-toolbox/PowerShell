[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact="High")]
Param(
    [Parameter(Mandatory = $True,
        Position = 0,
        ValueFromPipeline = $True,
        ValueFromPipelinebyPropertyName = $True)]
    [string[]] $ComputerNames,
    [string] $SourcePath = "\\ICEMAN\Public\Toolbox",
    [string] $DestinationPath = "C:\NotBackedUp\Public\Toolbox",
    [switch] $Mirror)

Begin
{
    Function Copy-Toolbox(        
        [string] $ComputerName,
        [string] $SourcePath,
        [string] $DestinationPath,
        [switch] $Mirror)
    {
        [string] $destination = `
            "\\$ComputerName\" `
            + $DestinationPath.Replace(":", "$")

        [string] $command = 'robocopy "$SourcePath" "$destination" /E'

        If ($Mirror)
        {
            $command += " /MIR"
        }

        Invoke-Expression $command
    }
}

Process
{
    $ComputerNames |
        ForEach-Object {
            [string] $computerName = $_

            If ($PSCmdlet.ShouldProcess($computerName) -eq $true)
            {
                Copy-Toolbox $computerName $SourcePath $DestinationPath -Mirror:$Mirror
            }
        }
}