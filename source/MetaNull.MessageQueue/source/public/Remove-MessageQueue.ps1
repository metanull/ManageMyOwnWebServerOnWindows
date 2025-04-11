<#
.SYNOPSIS
    Remove a message queue.
.DESCRIPTION
    This function removes the whole message queue.
.PARAMETER MessageQueueId
    The ID of the message queue to be removed.
.EXAMPLE
    Remove-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Medium')]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-MessageQueueId @args} )]
    [guid]$MessageQueueId
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $MetaNull.MessageQueue.MutexMessageQueue.WaitOne() | Out-Null
        # Remove the message queue
        Remove-Item "MetaNull:\MessageQueue\$MessageQueueId" -Recurse
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}