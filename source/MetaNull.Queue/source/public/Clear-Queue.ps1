<#
    .SYNOPSIS
        Remove all Commands from the queue

    .DESCRIPTION
        Remove all Commands from the queue

    .PARAMETER Id
        The Id of the queue
        
    .EXAMPLE
        Clear-Queue -Id $Id
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
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
    [guid] $Id
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        # Find the queue
        if(-not "$Id" -or -not (Test-Path "MetaNull:\Queues\$Id")) {
            throw  "Queue $Id not found"
        }

        # Remove the command
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            Remove-Item "MetaNull:\Queues\$Id\Commands\*" -Force -Recurse
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}