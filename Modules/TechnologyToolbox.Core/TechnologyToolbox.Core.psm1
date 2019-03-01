$privateScripts  = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude *.Tests.* )
$publicScripts  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude *.Tests.* )

foreach ($script in @($privateScripts + $publicScripts))
{
    . $script.FullName
}