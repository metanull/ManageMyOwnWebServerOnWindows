<#
.SYNOPSIS
    Adds a message to one or several message queue(s).
.DESCRIPTION
    Adds a message to one or several message queue(s).
.PARAMETER MessageQueueId
    The ID of the message queue(s) where message should be added to.
.PARAMETER Label
    The label of the message.
.PARAMETER MetaData
    The metadata of the message.
.OUTPUTS
    [int] the index of the added message in the queue
.EXAMPLE
    Push-Message -Id '12345678-1234-1234-1234-123456789012' -Label 'Test' -MetaData @{ Test = 'Test' }
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
[OutputType([int])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-MessageQueueId @args} )]
    [guid[]]$MessageQueueId,

    [Parameter(Mandatory, Position = 1)]
    [string]$Label,

    [Parameter(Mandatory = $false, Position = 2)]
    [AllowNull()]
    [object]$MetaData = $null
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $MetaNull.MessageQueue.MutexMessageQueue.WaitOne() | Out-Null
        
        $MessageData = [pscustomobject]@{
            MessageId = [guid]::NewGuid()
            Index = 1
            Label = $Label
            Date = ((Get-Date)|ConvertTo-JSon)
            MetaData = ($MetaData|ConvertTo-JSon)
        }

        # Add the message to the message store
        $MessageStore = New-Item -Path "MetaNull:\MessageStore\$($MessageData.MessageId)"
        $MessageStore | Set-ItemProperty -Name 'MessageId' -Value $MessageData.MessageId
        $MessageStore | Set-ItemProperty -Name 'Label' -Value $MessageData.Label
        $MessageStore | Set-ItemProperty -Name 'Date' -Value $MessageData.Date
        $MessageStore | Set-ItemProperty -Name 'MetaData' -Value $MessageData.MetaData

        # Add the reference to the message in each messagequeue
        $MessageQueueId | Foreach-Object {
            $MQID = $_
            $MessageData.Index = 1

            # Find the highest index in THIS queue
            $Item = Get-Item -Path "MetaNull:\MessageQueue\$MQID"
            $NewIndex = $Item | Get-ChildItem | Get-ItemProperty | Sort-Object -Property Index | Select-Object -Last 1 | ForEach-Object {
                $_.Index + 1
            }
            if($NewIndex -ne $null) {
                $MessageData.Index = $NewIndex
            }

            # Add the reference to THIS messagequeue
            $Message = New-Item -Path "MetaNull:\MessageQueue\$MQID\$($MessageData.Index)"
            $Message | Set-ItemProperty -Name 'MessageId' -Value $MessageData.MessageId
            $Message | Set-ItemProperty -Name 'Index' -Value $MessageData.Index
            $Message | Set-ItemProperty -Name 'Date' -Value $MessageData.Date

            # return the message id
            return $MessageData.Index
        }
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}