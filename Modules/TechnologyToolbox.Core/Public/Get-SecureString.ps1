<#
.SYNOPSIS
Gets a secure string (such as a password) from the console.

.DESCRIPTION
The Get-SecureString cmdlet reads secure data from the console. You can use it
to prompt a user for sensitive information (such as a password) that should be
obscured using asterisks (*).

.PARAMETER Prompt
Optional text for the prompt. If the string includes spaces, enclose it in
quotation marks. A colon (:) is automatically appended to the text that you
enter.

.EXAMPLE
$password = .\Get-SecureString.ps1 -Prompt Password

Description
-----------
This command displays the string "Password:" as a prompt. When a value is
entered and the Enter key is pressed, the command displays the string
"Password (confirm):" as a prompt. When the confirmation value is entered and
the Enter key is pressed, it confirms the two inputs match and the corresponding
SecureString is stored in the $password variable.

The following command can subsequently be used to convert the SecureString to
plain text:

$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

#>
function Get-SecureString {
    [CmdletBinding()]
    Param(
        [string] $Prompt = "Secure string")

    Begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
    }

    Process {
        [System.Security.SecureString] $secureString =
            Read-Host -Prompt $Prompt -AsSecureString

        [System.Security.SecureString] $confirmSecureString =
            Read-Host -Prompt "$Prompt (confirm)" -AsSecureString

        Write-Verbose "Validating input..."

        [string] $temp1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))

        [string] $temp2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmSecureString))

        If ($temp1 -ne $temp2) {
            Throw "Confirmation does not match."
        }

        return $secureString
    }
}