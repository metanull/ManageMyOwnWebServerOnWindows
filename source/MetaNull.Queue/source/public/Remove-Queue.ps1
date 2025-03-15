<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return $null -eq $_ -or ([guid]::TryParse($_, [ref]$ref))
    })]
    [Alias('QueueId')]
    [string] $Id,

    [Parameter(Mandatory = $false)]
    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    $DoForce = $Force.IsPresent -and $Force
    try {
        $QueueToRemove = Find-Queue -Scope $Scope -Name * | Where-Object { 
            $_.Id -eq $Id
        }

        if($QueueToRemove) {
            try {
                Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex)
                $QueueToRemove | ForEach-Object {
                    $_.RegistryKey | Remove-Item -Force:$DoForce
                }
            } finally {
                Unlock-ModuleMutex -Mutex ([ref]$Mutex)
            }
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
