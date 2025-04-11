<#
.SYNOPSIS
    Get a message queue.
.DESCRIPTION
    This function gets a message queue.
.PARAMETER Id
    The ID of the message queue to be retrieved. This is a mandatory parameter and must be provided.
.EXAMPLE
    Get-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
[OutputType([Object],[Object[]])]
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
        # Get the message queue and its properties
        Get-ItemProperty -Path "MetaNull:\MessageQueue\$MessageQueueId" | Select-Object -ExcludeProperty PS*
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}