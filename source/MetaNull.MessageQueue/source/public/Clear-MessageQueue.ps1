<#
.SYNOPSIS
    Clears the message queue for a specified queue name.
.DESCRIPTION
    This function clears the message queue for a specified queue name.
.PARAMETER MessageQueueId
    The ID of the message queue to be cleared.
.EXAMPLE
    Clear-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
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
        Get-Item "MetaNull:\MessageQueue\$MessageQueueId" | Get-ChildItem | Remove-Item | Out-Null
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}