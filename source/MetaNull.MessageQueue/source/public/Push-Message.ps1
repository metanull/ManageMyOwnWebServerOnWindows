<#
    .Synopsis
        Send a message to the queue (or broadcast to multiple queues).
#>

<#
    !!!!!!  Date = (Get-Date|ConvertTo-Json)
    Increment queue's AvailableMessageCount
    Update Queues's LastMessage

    + Increment SendCount
#>