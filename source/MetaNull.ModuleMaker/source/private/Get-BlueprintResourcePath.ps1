<#
    .SYNOPSIS
        Get the location of the Module's ResourceDirectory

    .EXAMPLE
        $Item = Get-BlueprintResourcePath
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param()
Process {
    if((Get-Variable INSIDE_MODULEMAKER_MODULE -ErrorAction SilentlyContinue)) {
        #INSIDE_MODULEMAKER_MODULE is a constant defined in the module
        #If it is set, then the script is run from a loaded module, PSScriptRoot = Directory of the psm1
        Get-Item (Join-Path $PSScriptRoot resource)
    } else {
        #Otherwise, the script was probably called from the command line or from a test, PSScriptRoot = Directory /source/private
        Get-Item (Join-Path (Split-Path (Split-Path $PSScriptRoot)) resource)
    }
}