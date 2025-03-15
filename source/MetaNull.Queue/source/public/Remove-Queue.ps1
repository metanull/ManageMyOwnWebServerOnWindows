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
        $Queue = Get-Queue -QueueId $QueueId -Scope $Scope
        if(-not $Queue) {
            throw  "Queue $QueueId not found"
        }

        # Remove the queue
        [System.Threading.Monitor]::Enter($METANULL_QUEUE_CONSTANTS.Lock)
        try {
            $Queue.RegistryKey | Remove-Item -Recurse -Force:$DoForce
        } finally {
            [System.Threading.Monitor]::Exit($METANULL_QUEUE_CONSTANTS.Lock)
        }
        
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
