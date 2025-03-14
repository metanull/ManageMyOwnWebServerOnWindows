<#
    .SYNOPSIS
    Remove the module's configuration from the Windows Registry
#>
[CmdletBinding()]
[OutputType()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope,

    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if(-not (Test-Registry -Scope $Scope) -eq $true) {
            # Not initialized
            return
        }

        # Create the registry key
        $RootPath = Get-RegistryPath -Scope $Scope
        Remove-Item -Path $RootPath -Force:$Force
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }    
}