<#
    .SYNOPSIS
        Remove all Commands from the queue
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [guid] $Id
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        # Find the queue
        $Queue = Get-Queue -Id $Id
        if(-not $Queue) {
            throw  "Queue $Id not found"
        }

        # Remove the command
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $Queue.Commands.RegistryKey | Remove-Item -Force
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }

        # Return the commands (without the registry key, as it was deleted)
        $Queue.Commands | ForEach-Object {
            $_.RegistryKey = $null
            $_ | Write-Output
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}