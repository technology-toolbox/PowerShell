$publicScripts  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude *.Tests.* )

foreach ($script in $publicScripts)
{
    . $script.FullName
}