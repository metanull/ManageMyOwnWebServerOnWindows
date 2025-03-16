<#
    .SYNOPSIS
        Return the default scope for MetaNull.Queue functions
#>
[CmdletBinding()]
[OutputType([string])]
param()
Process {
    if(Test-IsAdministrator) {
        return 'AllUsers'
    }
    return 'CurrentUser'
}