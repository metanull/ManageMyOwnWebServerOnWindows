<#
.SYNOPSIS
    Get statistics of a message queue.
.DESCRIPTION
    This function gets a message queue.
.PARAMETER Id
    The ID of the message queue to be retrieved. This is a mandatory parameter and must be provided.
.EXAMPLE
    Get-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
[OutputType([pscustomobject])]
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

        # Get the mesage queue and its properties, and its messages
        $MessageQueue = Get-Item "MetaNull:\MessageQueue\$Id"
        $MessageQueueProperties = $MessageQueue | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS*
        $Messages = Get-ChildItem "MetaNull:\MessageQueue\$Id\Messages\" | Sort-Object -Property PSChildName

        # Take the first and last message
        $FirstMessage,$LastMessage = ($Messages | Select-Object -First 1),($Messages | Select-Object -Last 1) | ForEach-Object {
            $Properties = Get-ChildItem "MetaNull:\MessageStore\$($_.PSChildName)" | Get-ItemProperty
            if($Properties.Date) {
                $Properties.Date = $Properties.Date | ConvertFrom-Json
            }
            $Properties | Add-Member -MemberType NoteProperty -Name 'Index' -Value ([int]$Properties.PSChildName)
            $Properties | select-object * | Select-Object -ExcludeProperty PS*
        }

        # Return the message queue statistics
        [pscustomobject]@{
            MessageQueue = [pscustomobject]@{
                Id = $Id
                Name = $MessageQueueProperties.Name
            }
            Size = $MessageQueueProperties.MaximumSize
            Used = $Messages.Count
            Free = $MessageQueueProperties.MaximumSize - $Messages.Count
            UsagePercent = $Messages.Count / $MessageQueueProperties.MaximumSize * 100
            FirstMessage = $FirstMessage | Select-Object -ExpandProperty Index
            FirstMessageDate = $FirstMessage | Select-Object -ExpandProperty Date
            LastMessage = $LastMessage | Select-Object -ExpandProperty Index
            LastMessageDate = $LastMessage | Select-Object -ExpandProperty Date
        } | Write-Output
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageQueue)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}