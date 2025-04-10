<#
.SYNOPSIS
    Remove a message queue.
.DESCRIPTION
    This function removes the whole message queue.
.PARAMETER Id
    The ID of the message queue to be removed. This is a mandatory parameter and must be provided.
.EXAMPLE
    Remove-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Medium')]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-MessageQueueId @args} )]
    [guid]$Id
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockMessageQueue)
    try {
        # Find the message queue
        if(-not "$Id" -or -not (Test-Path "MetaNull:\MessageQueue\$Id")) {
            throw  "MessageQueue $Id not found"
        }

        # Remove the messages
        Remove-Item "MetaNull:\MessageQueue\$Id" -Recurse
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageQueue)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}