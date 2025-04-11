<#
.SYNOPSIS
    Get the messages in a message queue.
.DESCRIPTION
    Get the messages in a message queue.
.PARAMETER MessageQueueId
    The ID of the message queue to be retrieved.
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

        # Get the messages in the queue
        $Messages = Get-Item -Path "MetaNull:\MessageQueue\$MessageQueueId" | Get-ChildItem | Get-ItemProperty
        $Messages | Sort-Object -Property Index | Foreach-Object {
            $Message = $_
            Get-Item -Path "MetaNull:\MessageStore\$($Message.MessageId)" | Get-ItemProperty | Select-Object -Property @(
                @{Name = 'MessageQueueId'; Expression = { $MessageQueueId }}
                @{Name = 'MessageId'; Expression = { [guid]($Message.MessageId) }}
                @{Name = 'Index'; Expression = { [int]$Message.Index }}
                @{Name = 'Label'; Expression = { $_.Label }}
                @{Name = 'Date'; Expression = { [datetime]($_.Date | ConvertFrom-Json) }}
                @{Name = 'MetaData'; Expression = { $_.MetaData | ConvertFrom-Json }}
            ) | Write-Output
        }
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}