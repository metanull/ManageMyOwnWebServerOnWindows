<#
    .SYNOPSIS
        Get the location of the Module's ResourceDirectory

    .EXAMPLE
        $Item = Get-BlueprintResourcePath
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [switch] $Test
)
Process {
    if(-not $Test) {
        # Running from within an installed module (PSScriptRoot is the path to the module's root directory)
        Get-Item (Join-Path $PSScriptRoot resource)
    } else {
        # Running from within a TEST (thus not from an installed module; PSScriptRoot is the path to the test script itself)
        Get-Item (Join-Path (Split-Path (Split-Path $PSScriptRoot)) resource)
    }
}