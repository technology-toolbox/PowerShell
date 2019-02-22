$publicScripts  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 )

foreach ($script in $publicScripts)
{
    . $script.FullName
}