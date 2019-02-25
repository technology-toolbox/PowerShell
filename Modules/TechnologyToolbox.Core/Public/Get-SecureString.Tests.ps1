. $PSScriptRoot\Get-SecureString.ps1

Describe 'Get-SecureString Tests' {
    Context '[Default prompt]' {
        [System.Security.SecureString] $securePassword = `
            ConvertTo-SecureString -String '{password}' -AsPlainText -Force

        Mock Read-Host {return $securePassword}

        It 'Returns expected SecureString' {

            [System.Security.SecureString] $result = Get-SecureString

            $result | Should Be $securePassword
        }

        Assert-MockCalled Read-Host -Times 2 -Exactly
        Assert-MockCalled Read-Host -Times 2 -Exactly `
            -ParameterFilter { $AsSecureString -eq $true }

        Assert-MockCalled Read-Host -Times 1 -Exactly `
            -ParameterFilter { $Prompt -eq 'Secure string' }

        Assert-MockCalled Read-Host -Times 1 -Exactly `
            -ParameterFilter { $Prompt -eq 'Secure string (confirm)' }
    }

    Context '[Custom prompt]' {
        [System.Security.SecureString] $securePassword = `
            ConvertTo-SecureString -String '{password}' -AsPlainText -Force

        Mock Read-Host {return $securePassword}

        It 'Uses custom prompt and returns expected SecureString' {

            [System.Security.SecureString] $result = `
                Get-SecureString -Prompt 'Password'

            $result | Should Be $securePassword
        }

        Assert-MockCalled Read-Host -Times 2 -Exactly
        Assert-MockCalled Read-Host -Times 2 -Exactly `
            -ParameterFilter { $AsSecureString -eq $true }

        Assert-MockCalled Read-Host -Times 1 -Exactly `
            -ParameterFilter { $Prompt -eq 'Password' }

        Assert-MockCalled Read-Host -Times 1 -Exactly `
            -ParameterFilter { $Prompt -eq 'Password (confirm)' }
    }

    Context '[Failed confirmation]' {
        [System.Security.SecureString] $secureString1 = `
            ConvertTo-SecureString -String '{foo}' -AsPlainText -Force

        [System.Security.SecureString] $secureString2 = `
            ConvertTo-SecureString -String '{bar}' -AsPlainText -Force

        Mock Read-Host {return $secureString1} `
            -ParameterFilter { $Prompt -eq 'Secure string' }

        Mock Read-Host {return $secureString2} `
            -ParameterFilter { $Prompt -eq 'Secure string (confirm)' }

        It 'Throws when confirmation does not match' {
            { Get-SecureString } | Should Throw 'Confirmation does not match.'
        }
    }
}