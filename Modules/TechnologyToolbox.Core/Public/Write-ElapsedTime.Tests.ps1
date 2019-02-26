. $PSScriptRoot\Get-Stopwatch.ps1
. $PSScriptRoot\Write-ElapsedTime.ps1

Describe 'Write-ElapsedTime Tests' {
    $stopwatch = Get-Stopwatch

    Start-Sleep -Milliseconds 50

    $stopwatch.Stop()

    [string] $elapsedTime = [string]::Format(
        "{0:00}:{1:00}:{2:00}.{3:000}",
        $stopwatch.Elapsed.Hours,
        $stopwatch.Elapsed.Minutes,
        $stopwatch.Elapsed.Seconds,
        $stopwatch.Elapsed.Milliseconds)

    Context '[Default parameters]' {
        Mock Write-Host {}

        It 'Writes elapsed time of Stopwatch object' {
            Write-ElapsedTime -Stopwatch $stopwatch
        }

        Assert-MockCalled Write-Host -Times 1 -Exactly
        Assert-MockCalled Write-Host -Times 1 -Exactly `
            -ParameterFilter {
                $Object -eq ('Elapsed time: ' + $elapsedTime) -and
                $ForegroundColor -eq [System.ConsoleColor]::Cyan
            }
    }

    Context '[Custom foreground color]' {
        Mock Write-Host {}

        $foregroundColor = [System.ConsoleColor]::White

        It 'Writes elapsed time with expected foreground color' {
            Write-ElapsedTime `
                -Stopwatch $stopwatch `
                -ForegroundColor $foregroundColor
        }

        Assert-MockCalled Write-Host -Times 1 -Exactly
        Assert-MockCalled Write-Host -Times 1 -Exactly `
            -ParameterFilter {
                $Object -eq ('Elapsed time: ' + $elapsedTime) -and
                $ForegroundColor -eq $foregroundColor
            }
    }

    Context '[Custom Prefix and Suffix]' {
        Mock Write-Host {}

        [string] $prefix = '{Prefix}'
        [string] $suffix = '{Suffix}'

        It 'Writes elapsed time with expected Prefix/Suffix' {
            Write-ElapsedTime `
                -Stopwatch $stopwatch `
                -Prefix $prefix `
                -Suffix $suffix
        }

        Assert-MockCalled Write-Host -Times 1 -Exactly
        Assert-MockCalled Write-Host -Times 1 -Exactly `
            -ParameterFilter { $Object -eq ($prefix + $elapsedTime + $suffix) }
    }
}