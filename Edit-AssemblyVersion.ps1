<#
.SYNOPSIS
Modifies the specified assembly version (for example, to increment the "build"
component).

.DESCRIPTION
The Edit-AssemblyVersion cmdlet generates a new version starting from a
"reference" version.

Edit-AssemblyVersion returns an object with OldVersion and NewVersion
properties.

Without any of the optional parameters, Edit-AssemblyVersion does not do
anything useful. However, by specifying Major, Minor, Build, and/or Revision
parameters, a new version is generated based on the parameter values.

Note the Major, Minor, Build, and Revision parameters can be specified either
as numeric string values (e.g. "1") or as "Increment" -- in which case, the
corresponding components of the "reference" version are increased by one.

.PARAMETER Version
Specifies the "reference" version to use when generating the new version. The
parameter name ("Version") is optional. This value is returned in the output as
the OldVersion.

.PARAMETER Major
Specifies the "major" version to use when generating the new version. Specify
either a numeric string value (to use a specific value) or "Increment" to
increase the major component in the "reference" version by one.

.PARAMETER Minor
Specifies the "minor" version to use when generating the new version. Specify
either a numeric string value (to use a specific value) or "Increment" to
increase the minor component in the "reference" version by one.

.PARAMETER Build
Specifies the "build" number to use when generating the new version. Specify
either a numeric string value (to use a specific value) or "Increment" to
increase the build component in the "reference" version by one.

.PARAMETER Revision
Specifies the "revision" to use when generating the new version. Specify
either a numeric string value (to use a specific value) or "Increment" to
increase the revision component in the "reference" version by one.

.PARAMETER AsString
Indicates that this cmdlet converts the OldVersion and NewVersion properties in
the returned object to strings. By default, the property values are returned as
Version objects.

.EXAMPLE
.\Edit-AssemblyVersion.ps1 -Version 1.0

OldVersion NewVersion
---------- ----------
1.0        1.0

Description
-----------
This command returns a new version that is identical to the "reference" version.

.EXAMPLE
.\Edit-AssemblyVersion.ps1 -Version 1.0 -Major 2

OldVersion NewVersion
---------- ----------
1.0        2.0

Description
-----------
This command overwrites the major version with a specific value.

.EXAMPLE
.\Edit-AssemblyVersion.ps1 2.6 -Major Increment -Minor 0

OldVersion NewVersion
---------- ----------
2.6        3.0

Description
-----------
This command increments the major version by one and resets the minor version to
0.

.EXAMPLE
.\Edit-AssemblyVersion.ps1 2.0 -Build Increment

OldVersion NewVersion
---------- ----------
2.0        2.0.1

Description
-----------
This command increments the build version by one. Since the "reference" version
did not contain a build number, it was initialized with a default value of 0.

.EXAMPLE
.\Edit-AssemblyVersion.ps1 2.0 -Revision Increment

OldVersion NewVersion
---------- ----------
2.0        2.0.0.1

Description
-----------
This command increments the revision by one. Since the "reference" version
did not contain a build number or a revision, they were both initialized to 0
(and the revision was subsequently increased by one).

.EXAMPLE
.\Edit-AssemblyVersion.ps1 1.0 -Major 2 | select -ExpandProperty NewVersion

Major  Minor  Build  Revision
-----  -----  -----  --------
2      0      -1     -1

Description
-----------
This command overwrites the major version and returns the "expanded" form of the
NewVersion (which is a System.Version object with Major, Minor, Build, and
Revision properties).

.EXAMPLE
.\Edit-AssemblyVersion.ps1 1.0 -Major 2 -AsString | select -ExpandProperty NewVersion

2.0

Description
-----------
This command overwrites the major version and returns the NewVersion as a simple
string.

.LINK
https://msdn.microsoft.com/en-us/library/system.version.aspx

#>
[CmdletBinding()]
Param(
    [Parameter(Position=0, Mandatory, ValueFromPipeLine=$true)]
    [Version] $Version,
    [string] $Major,
    [string] $Minor,
    [string] $Build,
    [string] $Revision,
    [switch] $AsString
)

Begin
{
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    Function CreateOutputObject
    {
        Param(
            [Version] $OldVersion,
            [Version] $NewVersion,
            [switch] $AsString)

        $result = New-Object -TypeName PSObject

        $propertyValue = $OldVersion
        If ($AsString)
        {
            $propertyValue = $OldVersion.ToString()
        }
        
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name OldVersion `
            -Value $propertyValue
        
        $propertyValue = $NewVersion
        If ($AsString)
        {
            $propertyValue = $NewVersion.ToString()
        }
            
        $result | Add-Member `
            -MemberType NoteProperty `
            -Name NewVersion `
            -Value $propertyValue

        $result
    }
}

Process
{
    If ([string]::IsNullOrEmpty($Major) -eq $true)
    {
        $Major = $Version.Major
    }
    ElseIf ($Major -eq "Increment")
    {
        $Major = ($Version.Major + 1).ToString()
    }

    If ([string]::IsNullOrEmpty($Minor) -eq $true)
    {
        $Minor = $Version.Minor
    }
    ElseIf ($Minor -eq "Increment")
    {
        $Minor = ($Version.Minor + 1).ToString()
    }

    If ([string]::IsNullOrEmpty($Build) -eq $true)
    {
        If ($Version.Build -ne -1)
        {
            $Build = $Version.Build
        }
    }
    ElseIf ($Build -eq "Increment")
    {
        If ($Version.Build -eq -1)
        {
            $Build = "1"
        }
        Else
        {
            $Build = ($Version.Build + 1).ToString()
        }
    }

    If ([string]::IsNullOrEmpty($Revision) -eq $true)
    {
        If ($Version.Revision -ne -1)
        {
            $Revision = $Version.Revision
        }
    }
    ElseIf ($Revision -eq "Increment")
    {
        If ($Version.Revision -eq -1)
        {
            $Revision = "1"
        }
        Else
        {
            $Revision = ($Version.Revision + 1).ToString()
        }
    }

    If ([string]::IsNullOrEmpty($Revision) -eq $true)
    {
        If ([string]::IsNullOrEmpty($Build) -eq $true)
        {
            $newVersion = [Version]::new($Major, $Minor)
        }
        Else
        {
            $newVersion = [Version]::new($Major, $Minor, $Build)
        }
    }
    Else
    {
        $newVersion = [Version]::new($Major, $Minor, $Build, $Revision)
    }

    CreateOutputObject `
        -OldVersion $Version `
        -NewVersion $newVersion `
        -AsString:$AsString
}