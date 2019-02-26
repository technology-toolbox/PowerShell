. $PSScriptRoot\Get-Stopwatch.ps1

Describe 'Get-Stopwatch Tests' {
    It 'Returns running Stopwatch object' {
        $result = Get-Stopwatch

        $result | Should BeOfType System.Diagnostics.Stopwatch

        $result.IsRunning | Should Be $true

        $result.Stop()
    }
}