<#
    .SYNOPSIS
        Remove all Commands from the queue
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [guid] $Id
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        # Find the queue
        if(-not "$Id" -or -not (Test-Path "MetaNull:\Queues\$Id")) {
            throw  "Queue $Id not found"
        }

        # Remove the command
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            Remove-Item "MetaNull:\Queues\$Id\Commands\*" -Force -Recurse
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}