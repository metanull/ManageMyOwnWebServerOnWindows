<# See Get-MessageQueue 

    Idea:

    MetaNull.MessageQueue:\\MessageStore\{guid} -> stores the message details
    MetaNull.MessageQueue:\\MessageQueue\{guid}\Messages\{index} -> stores the ordered message list

    => It permits having message sent to multiple queues, but details stored only once
    => It also permits deleting a message from a queue, but not from the others
    => Note: Remove-Message should check if the message is appearing in other queues; if not, it should be deleted from the message store as well

@{
    Id = [guid]::NewGuid()
    Name = 'Queue 1'
    MaximumSize = 1000
    MessageCount = 0
    MessageRetentionPeriod = 7
    LastMessageReceived = (Get-Date).AddDays(-1)
}


    !!!!!!  Date = (Get-Date|ConvertTo-Json)

    + Increment ReceiveCount


#>