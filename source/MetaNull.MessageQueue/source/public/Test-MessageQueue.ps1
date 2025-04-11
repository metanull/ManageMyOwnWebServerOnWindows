<#
.SYNOPSIS
    Test if a Message Queue exists
.DESCRIPTION
    Test if a Message Queue exists
.PARAMETER MessageQueueId
    The Id of the message queue to be retrieved.
.PARAMETER Name
    Lookup by Name rather than by Id.
.EXAMPLE
    Test-MessageQueue -Id '12345678-1234-1234-1234-123456789012'
.EXAMPLE
    Test-MessageQueue -Name 'MyQueue'
.OUTPUTS
    [bool] True if the message queue exists, otherwise false.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
[OutputType([bool])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {Resolve-MessageQueueId @args} )]
    [guid]$MessageQueueId
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        return Test-Path "MetaNull:\MessageQueue\$MessageQueueId"
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}