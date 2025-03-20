<#
    .SYNOPSIS
        Remove all Commands from the queue

    .DESCRIPTION
        Remove all Commands from the queue

    .PARAMETER Id
        The Id of the queue

    .EXAMPLE
        Clear-Queue -Id $Id
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Medium')]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-QueueId @args} )]
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
        Remove-Item "MetaNull:\Queues\$Id\Commands\*" -Force -Recurse
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}