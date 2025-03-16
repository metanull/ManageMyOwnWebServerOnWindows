<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return ([guid]::TryParse($_, [ref]$ref))
    })]
    [string] $Id,

    [Parameter(Mandatory = $false)]
    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    $DoForce = $Force.IsPresent -and $Force
    try {
        # Find the queue
        $Queue = Get-Queue -Id $Id
        if(-not $Queue) {
            throw  "Queue $Id not found"
        }
        # Remove the queue
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $Queue.RegistryKey | Remove-Item -Recurse -Force:$DoForce
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
