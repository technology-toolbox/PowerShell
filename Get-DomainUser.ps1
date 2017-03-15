[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeLine = $true)]
    [String] $LogonName
)

Begin
{
    $ErrorActionPreference = "Stop"

    [Int32] $ACCOUNTDISABLE       = 0x000002
    [Int32] $DONT_EXPIRE_PASSWORD = 0x010000
    [Int32] $PASSWORD_EXPIRED     = 0x800000
}

Process
{
    $searcher = [adsisearcher]("(&" `
        + "(objectCategory=person)" `
        + "(objectClass=User)" `
        + "(sAMAccountName=$LogonName)" `
        + ")")

    $searchResults = $searcher.FindAll()

    If ($searchResults.Count -eq 0)
    {
        Throw "The specified user ($LogonName) was not found."
    }
    ElseIf ($searchResults.Count -gt 1)
    {
        Throw "More than one user ($LogonName) was found."
    }

    $user = [adsi]$searchResults[0].Properties.adspath[0]

    [String] $samAccountName = $user.sAMAccountName[0]

    [String] $displayName = $null

    If ($user.Properties.displayName -ne $null)
    {
        $displayName = $user.Properties.displayName[0]
    }

    [String] $mail= $null
    
    If ($user.Properties.mail -ne $null)
    {
        $mail = $user.Properties.mail[0]
    }

    [Int64] $timestamp = 0
    
    If ($user.Properties.lastLogonTimestamp -ne $null)
    {
        $timestamp = $user.ConvertLargeIntegerToInt64(
            $user.Properties.lastLogonTimestamp[0])
    }
    
    [DateTime] $lastLogontimeStamp = [DateTime]::FromFileTime(
        $timestamp)

    [Boolean] $enabled = -not [Boolean](
        $user.userAccountControl[0] -band $ACCOUNTDISABLE)

    [Boolean] $passwordExpired = [Boolean](
        $user.userAccountControl[0] -band $PASSWORD_EXPIRED)

    $userSid  = New-Object System.Security.Principal.SecurityIdentifier(
        $user.objectSid[0], 0)

    $result = New-Object -TypeName PSObject

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name LoginName `
        -Value $samAccountName

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name DisplayName `
        -Value $displayName

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name EmailAddress `
        -Value $mail

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name LastLogonTimestamp `
        -Value $lastLogontimeStamp
            
    $result | Add-Member `
        -MemberType NoteProperty `
        -Name Enabled `
        -Value $enabled

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name PasswordExpired `
        -Value $passwordExpired

    $result | Add-Member `
        -MemberType NoteProperty `
        -Name SID `
        -Value $userSid.ToString()

    $result
}
