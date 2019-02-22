<#
.SYNOPSIS
Gets the user sessions for the local computer or a remote computer.

.DESCRIPTION
The Get-UserSession cmdlet gets the user sessions on a local or remote computer.

Without parameters, this cmdlet gets all of the user sessions on the local
computer.

.EXAMPLE
.\Get-UserSession.ps1

MachineName : .
UserName    : jjameson
SessionName : console
Id          : 1
State       : Active
IdleTime    : none
LogonTime   : 7/31/2017 5:47:00 AM

#>
[CmdletBinding()]
Param(
    [String[]] $ComputerName = @(".")
)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function CreateUserSessionObject()
    {
        Param(
            [String] $MachineName,
            [String] $UserName,
            [String] $SessionName,
            [Int] $Id,
            [String] $State,
            [String] $IdleTime,
            [DateTime] $LogonTime
        )

        $result = New-Object -TypeName PSObject

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name MachineName `
            -Value $MachineName

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name UserName `
            -Value $UserName

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name SessionName `
            -Value $SessionName

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name Id `
            -Value $Id

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name State `
            -Value $State

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name IdleTime `
            -Value $IdleTime

        $result | Add-Member `
            -MemberType NoteProperty `
            -Name LogonTime `
            -Value $LogonTime

        return $result
    }

    Function GetUserSessions()
    {
        Param(
            [String] $ComputerName
        )

        $queryResults = $null

        If ($ComputerName -eq ".")
        {
            Write-Verbose "Querying users on local computer..."

            $queryResults = query user
        }
        Else
        {
            Write-Verbose "Querying users on computer ($ComputerName)..."

            Try
            {
                # Redirect stderr to stdout (to avoid outputting "No User exists
                # for *" when no user sessions are found on the specified computer)
                $queryResults = query user /server:$ComputerName 2>&1
            }
            Catch
            {
                If ($_.Exception.Message -eq "No User exists for *")
                {
                    # No users are currently logged on
                    return
                }

                Throw
            }
        }

        $columnOffsets = New-Object PSObject -Property @{
            "UserName" = 0;
            "SessionName" = 0;
            "Id" = 0;
            "State" = 0;
            "IdleTime" = 0;
            "LogonTime" = 0;
        }

        $parseColumnOffsets = $true

        $queryResults |
            foreach {
                $queryResult = $_

                If ($parseColumnOffsets -eq $true)
                {
                    $columnOffsets.UserName = $queryResult.IndexOf("USERNAME")
                    $columnOffsets.SessionName =
                        $queryResult.IndexOf("SESSIONNAME")

                    $columnOffsets.Id = $queryResult.IndexOf("ID")
                    $columnOffsets.State = $queryResult.IndexOf("STATE")
                    $columnOffsets.IdleTime = $queryResult.IndexOf("IDLE TIME")
                    $columnOffsets.LogonTime =
                        $queryResult.IndexOf("LOGON TIME")

                    $parseColumnOffsets = $false
                }
                Else
                {
                    $userName = $queryResult.Substring(
                        $columnOffsets.UserName,
                        $columnOffsets.SessionName - $columnOffsets.UserName).Trim()

                    $sessionName = $queryResult.Substring(
                        $columnOffsets.SessionName,
                        $columnOffsets.Id - $columnOffsets.SessionName).Trim()
            
                    $id = $queryResult.Substring(
                        $columnOffsets.Id,
                        $columnOffsets.State - $columnOffsets.Id).Trim()

                    $state = $queryResult.Substring(
                        $columnOffsets.State,
                        $columnOffsets.IdleTime - $columnOffsets.State).Trim()

                    If ($state -eq "Disc")
                    {
                        $state = "Disconnected"
                    }

                    $idleTime = $queryResult.Substring(
                        $columnOffsets.IdleTime,
                        $columnOffsets.LogonTime - $columnOffsets.IdleTime).Trim()

                    $logonTime = $queryResult.Substring(
                        $columnOffsets.LogonTime).Trim()

                    CreateUserSessionObject `
                        -MachineName $ComputerName `
                        -UserName $userName `
                        -SessionName $sessionName `
                        -Id $id `
                        -State $state `
                        -IdleTime $idleTime `
                        -LogonTime $logonTime
                }
            }
    }
}

Process
{
    $ComputerName |
        foreach {
            GetUserSessions -ComputerName $_
        }
}