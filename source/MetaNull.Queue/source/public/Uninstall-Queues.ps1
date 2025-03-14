<#
    .SYNOPSIS
    Remove the module's configuration from the Windows Registry
#>
[CmdletBinding()]
[OutputType()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if(-not (Test-QueuesInstalled -Scope $Scope) -eq $true -and -not ($Force.IsPresent -and $Force)) {
            # Not initialized
            Write-Verbose "Registry not initialized for $Scope"
            return
        }

        # Create the registry key
        $RootPath = Get-RegistryPath -Scope $Scope
        Write-Verbose "Removing registry key $RootPath"
        Remove-Item -Path $RootPath -Force:$Force
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }    
}