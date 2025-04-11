<#
.SYNOPSIS
    Get and remove the oldest message in a message queue.
.DESCRIPTION
    Get and remove the oldest message in a message queue.
.PARAMETER MessageQueueId
    The ID of the message queue(s) where message should be added to.
.EXAMPLE
    Pop-Message -Id '12345678-1234-1234-1234-123456789012'
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
[OutputType([Object],[Object[]])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-MessageQueueId @args} )]
    [guid[]]$MessageQueueId
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $MetaNull.MessageQueue.MutexMessageQueue.WaitOne() | Out-Null

        # Get the one oldest message in the queue
        $Messages = Get-Item -Path "MetaNull:\MessageQueue\$MessageQueueId" | Get-ChildItem | Get-ItemProperty
        $MessageQueueItem = $Messages | Sort-Object -Property Index | Select-Object -First 1 | Foreach-Object {
            $Message = $_
            Get-Item -Path "MetaNull:\MessageStore\$($Message.MessageId)" | Get-ItemProperty | Select-Object -Property @(
                @{Name = 'MessageQueueId'; Expression = { $MessageQueueId }}
                @{Name = 'MessageId'; Expression = { [guid]($Message.MessageId) }}
                @{Name = 'Index'; Expression = { [int]$Message.Index }}
                @{Name = 'Label'; Expression = { $_.Label }}
                @{Name = 'Date'; Expression = { [datetime]($_.Date | ConvertFrom-Json | Select-Object -ExpandProperty Value) }}
                @{Name = 'Message'; Expression = { $_.MetaData | ConvertFrom-Json }}
            )
        }

        # Remove the message from the message queue (but not from the message store)
        Get-Item -Path "MetaNull:\MessageQueue\$MessageQueueId" | Get-ChildItem | Where-Object {
            $_.PSChildName -eq $MessageQueueItem.Index
        } | Remove-Item

        # Return the message
        $MessageQueueItem | Write-Output
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}