<#
.SYNOPSIS
    Create a new message queue.
.DESCRIPTION
    This function creates a new message queue.
.PARAMETER Name
    The name of the message queue to be created.
.PARAMETER MaximumSize
    The maximum size of the message queue.
    This is an optional parameter and defaults to 100 messages.
.PARAMETER MessageRetentionPeriod
    The message retention period in days.
    This is an optional parameter and defaults to 7 days.
.EXAMPLE
    New-MessageQueue -Name 'MyQueue' -MaximumSize 100 -MessageRetentionPeriod 7
.OUTPUTS
    [guid] The ID of the newly created message queue.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Medium')]
[OutputType([guid])]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Name,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateRange(1, 10000)]
    [int]$MaximumSize = 100,
    
    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateRange(1, 365)]
    [int]$MessageRetentionPeriod = 7
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $MetaNull.MessageQueue.MutexMessageQueue.WaitOne() | Out-Null

        # Check if the queue already exists
        if(Find-MessageQueue -Name $Name) {
            throw "A MessageQueue with name $Name already exists."
        }
        
        # Create the message queue
        $MessageQueueId = New-Guid
        $Item = New-Item -Path "MetaNull:\MessageQueue\$MessageQueueId"
        $Item | Set-ItemProperty -Name 'MessageQueueId' -Value $MessageQueueId
        $Item | Set-ItemProperty -Name 'Name' -Value $Name
        $Item | Set-ItemProperty -Name 'MaximumSize' -Value $MaximumSize
        $Item | Set-ItemProperty -Name 'MessageRetentionPeriod' -Value $MessageRetentionPeriod

        return $MessageQueueId
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}