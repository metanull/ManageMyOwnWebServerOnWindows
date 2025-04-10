<#
.SYNOPSIS
    Get a message queue.
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

        # Get the mesage queue and its properties
        $MessageQueue = Get-Item "MetaNull:\MessageQueue\$Id"
        $MessageQueueProperties = $MessageQueue | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS*

        $MessageQueueProperties | Add-Member -MemberType NoteProperty -Name 'MessageQueueId' -Value ([guid]::new($MessageQueue.PSChildName))
        $MessageQueueProperties | Write-Output
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.LockMessageQueue)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}