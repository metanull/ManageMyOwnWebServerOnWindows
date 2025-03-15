<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return ([guid]::TryParse($_, [ref]$ref))
    })]
    [string] $QueueId,

    [Parameter(Mandatory = $false)]
    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    $DoForce = $Force.IsPresent -and $Force
    try {
        $Queue = Get-Queue -QueueId $QueueId
        if(-not $Queue) {
            throw  "Queue $QueueId not found"
        }

        # Remove the queue
        try {
            Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex) | Out-Null
            $Queue.RegistryKey | Remove-Item -Recurse -Force:$DoForce
        } finally {
            Unlock-ModuleMutex -Mutex ([ref]$Mutex) | Out-Null
        }
        
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
