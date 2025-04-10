<#
.SYNOPSIS
    Clears the message queue from outdated or excess messages.
.DESCRIPTION
    This function clears the message queue from outdated or excess messages.
.PARAMETER QueueName
    The name of the queue to be cleared.
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

        # Get the properties of the message queue
        $CurrentDate = (Get-Date)
        $MaximumSize = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").MaximumSize
        #$MessageCount = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").MessageCount
        $MessageRetentionPeriod = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").MessageRetentionPeriod
        #$LastMessage = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").LastMessage
        #if([string]::IsNullOrEmpty($LastMessage)) {
        #    $LastMessage = (Get-Date)
        #} else {
        #    $LastMessage = ($LastMessage|ConvertFrom-Json)
        #}
        

        # REDO: Get-Item to variable, then get-itemproperty, then measure-object on the variable
        # REDO: Get-Item to variable, then get-itemproperty, then measure-object on the variable
        # REDO: Get-Item to variable, then get-itemproperty, then measure-object on the variable
        # REDO: Get-Item to variable, then get-itemproperty, then measure-object on the variable
        # REDO: Get-Item to variable, then get-itemproperty, then measure-object on the variable
        
        # Remove excess messages
        if($MessageCount -gt $MaximumSize) {
            $MessageList = [object[]](Get-ChildItem "MetaNull:\MessageQueue\$Id\Messages" -ErrorAction SilentlyContinue | Foreach-Object {
                $_ | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* | Write-Output
            } | Sort-Object -Property Index)

            $ExcessMessages = $MessageCount - $MaximumSize
            $FirstIndex = ($MessageList | Select-Object -First 1)
            $FirstIndex..($FirstIndex + $ExcessMessages - 1) | ForEach-Object {
                Remove-Item "MetaNull:\MessageQueue\$Id\Messages\$($_)"
            }
        }
        # Remove outdated messages
        if($LastMessage -lt ($CurrentDate.AddDays(-$MessageRetentionPeriod))) {
            $MessageList = [object[]](Get-ChildItem "MetaNull:\MessageQueue\$Id\Messages" -ErrorAction SilentlyContinue | Foreach-Object {
                $_ | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* | Write-Output
            } | Sort-Object -Property Index)
            $MessageList | Where-Object {
                $MessageDate = ($_.Date|ConvertFrom-Json)
                $MessageDate -lt ($CurrentDate.AddDays(-$MessageRetentionPeriod))
            } | ForEach-Object {
                Remove-Item "MetaNull:\MessageQueue\$Id\Messages\$($_.Index)"
            }
        }
        # Remove leftover messages from the MessageStore
        $MessageQueueEntries = Get-ChildItem "MetaNull:\MessageQueue\*\Messages\" -ErrorAction SilentlyContinue | Foreach-Object {
            $_ | Get-ItemProperty | Select-Object -ExpandProperty Id | Write-Output
        }
        Get-ChildItem "MetaNull:\MessageStore" | Where-Object {
            $_.PSChildName -notin $MessageQueueEntries
        } | ForEach-Object {
            Remove-Item "MetaNull:\MessageStore\$($_.PSChildName)" -Recurse
        }
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageQueue)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}