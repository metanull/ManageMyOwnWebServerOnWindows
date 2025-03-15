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
    $Mutex = $null
    try {
        Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex) | Out-Null

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
        Unlock-ModuleMutex -Mutex ([ref]$Mutex) | Out-Null
        $ErrorActionPreference = $BackupErrorActionPreference
    }    
}