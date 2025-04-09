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
    [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockRead)
    [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.LockWrite)
    try {
        # Find the message queue
        if(-not "$Id" -or -not (Test-Path "MetaNull:\MessageQueue\$Id")) {
            throw  "MessageQueue $Id not found"
        }

        $CurrentDate = (Get-Date)
        $MaximumSize = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").MaximumSize
        $MessageCount = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").MessageCount
        $MessageRetentionPeriod = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").MessageRetentionPeriod
        $LastMessage = (Get-ItemProperty "MetaNull:\MessageQueue\$Id").LastMessage
        if([string]::IsNullOrEmpty($LastMessage)) {
            $LastMessage = (Get-Date)
        } else {
            $LastMessage = [datetime]($LastMessage|ConvertFrom-Json)
        }
        
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
                $MessageDate = [datetime]($_.Date|ConvertFrom-Json)
                $MessageDate -lt ($CurrentDate.AddDays(-$MessageRetentionPeriod))
            } | ForEach-Object {
                Remove-Item "MetaNull:\MessageQueue\$Id\Messages\$($_.Index)"
            }
        }
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockWrite)
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockRead)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}