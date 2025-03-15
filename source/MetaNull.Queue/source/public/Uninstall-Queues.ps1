<#
    .SYNOPSIS
    Remove the module's configuration from the Windows Registry
#>
[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    [System.Threading.Monitor]::Enter($METANULL_QUEUE_CONSTANTS.Lock)
    try {

        if(-not (Test-QueuesInstalled -Scope $Scope) -eq $true -and -not ($Force.IsPresent -and $Force)) {
            # Not initialized
            Write-Verbose "Registry not initialized for $Scope"
            return
        }

        # Create the registry key
        $RootPath = Get-RegistryPath -Scope $Scope
        Write-Verbose "Removing registry key $RootPath"
        Remove-Item -Path $RootPath -Recurse -Force:$Force
    } finally {
        [System.Threading.Monitor]::Exit($METANULL_QUEUE_CONSTANTS.Lock)

        $ErrorActionPreference = $BackupErrorActionPreference
    }    
}