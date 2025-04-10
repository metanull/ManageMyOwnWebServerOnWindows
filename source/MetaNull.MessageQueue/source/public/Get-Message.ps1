<#
    !!!!!!  Date = (Get-Date|ConvertTo-Json)

    + Increment ReceiveCount


    DON'T Decrement queue's AvailableMessageCount
    DON'T Update Queues's LastMessage (if the last message was removed)

    unless if parameter -Pop is set to $true
    + Decrement MessageCount
    + Decrement AvailableMessageCount
    + Update Queues's LastMessage (if the last message was removed)
#>

<#
.SYNOPSIS
    Get message(s), without removing them from the message queue.
.DESCRIPTION
    Get message(s), without removing them from the message queue.
.PARAMETER Id
    The ID of the message queue to be cleared. This is a mandatory parameter and must be provided.
.EXAMPLE
        Get-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
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
    try {
        # Find the message queue
        if(-not "$Id" -or -not (Test-Path "MetaNull:\MessageQueue\$Id")) {
            throw  "MessageQueue $Id not found"
        }

        [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockMessageQueue)
        try {
            # Get the message(s) from the MessageQueue
            $Messages = Get-Item "MetaNull:\MessageQueue\$Id\Messages" | Get-ChildItem | Foreach-Object {
                $Message = $_ | Get-ItemProperty
                $Message | Add-Member -MemberType NoteProperty -Name MessageQueueId -Value ([guid]$Id)
                $Message | Add-Member -MemberType NoteProperty -Name Index -Value ([int]($_.PSChildName))
                $Message | Write-Output
            } | Sort-Object -Property Index | ForEach-Object {
                $Message = $_
                # Get the message details from the MessageStore
                [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockMessageStore)
                try {
                    $MessageDetails = Get-Item "MetaNull:\MessageStore\$($Message.Id)" | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS*
                } finally {
                    [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageStore)
                }
                $MessageDetails | Add-Member -MemberType NoteProperty -Name MessageQueueId -Value $Message.MessageQueueId
                $MessageDetails | Add-Member -MemberType NoteProperty -Name Id -Value $Message.Id
                $MessageDetails | Add-Member -MemberType NoteProperty -Name Index -Value $Message.Index
                $MessageDetails | Write-Output
            }
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageQueue)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}