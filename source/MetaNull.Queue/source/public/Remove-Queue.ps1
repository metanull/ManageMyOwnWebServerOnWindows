<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )
            Get-ChildItem -Path "MetaNull:\Queues" | Split-Path -Leaf | Where-Object {$_ -like "$wordToComplete*"}
        } )]
    [guid] $Id,

    [Parameter(Mandatory = $false)]
    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        # Test if the queue exists
        if(-not "$Id" -or -not (Test-Path "MetaNull:\Queues\$Id")) {
            throw  "Queue $Id not found"
        }

        # Remove the queue
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $DoForce = $Force.IsPresent -and $Force
            Remove-Item "MetaNull:\Queues\$Id" -Recurse -Force:$DoForce
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
