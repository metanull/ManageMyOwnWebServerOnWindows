<#
    !!!!!!  Date = (Get-Date|ConvertTo-Json)

    + Increment ReceiveCount

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
    [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockMessageQueue)
    try {
        # Find the message queue
        if(-not "$Id" -or -not (Test-Path "MetaNull:\MessageQueue\$Id")) {
            throw  "MessageQueue $Id not found"
        }

        # Get the oldest message from the MessageQueue
        $Messages = Get-Item "MetaNull:\MessageQueue\$Id\Messages" | Get-ChildItem | Foreach-Object {
            $Message = $_ | Get-ItemProperty
            $Message | Add-Member -MemberType NoteProperty -Name MessageQueueId -Value ([guid]$Id)
            $Message | Add-Member -MemberType NoteProperty -Name Index -Value ([int]($_.PSChildName))
            $Message | Write-Output
        } | Sort-Object -Property Index | Select-Object -First 1 | ForEach-Object {
            # Get the message details from the MessageStore
            [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockMessageStore)
            try {
                $MessageDetails = Get-Item "MetaNull:\MessageStore\$($_.Id)" | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS*
            } finally {
                [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageStore)
            }
            $MessageDetails | Add-Member -MemberType NoteProperty -Name MessageQueueId -Value $_.MessageQueueId
            $MessageDetails | Add-Member -MemberType NoteProperty -Name Id -Value $_.Id
            $MessageDetails | Add-Member -MemberType NoteProperty -Name Index -Value $_.Index
            $MessageDetails | Write-Output

            # Remove the message from the MessageQueue (and not from the messagestore, which would be done by Optimize-MessageQueue)
            Remove-Item "MetaNull:\MessageQueue\$Id\Messages\$($_.Index)"
        }
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageQueue)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}