<#
    .SYNOPSIS
        Removes a Queue

    .DESCRIPTION
        Removes a Queue, and all its commands

    .PARAMETER Id
        The Id of the Queue to remove

    .PARAMETER Force
        Force the removal of the Queue
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'High')]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-QueueId @args} )]
    [guid] $Id,

    [Parameter(Mandatory = $false)]
    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        # Test if the queue exists
        if(-not "$Id" -or -not (Test-Path "MetaNull:\Queues\$Id")) {
            throw  "Queue $Id not found"
        }
        # Remove the queue
        $DoForce = $Force.IsPresent -and $Force
        Remove-Item "MetaNull:\Queues\$Id" -Recurse -Force:$DoForce
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
