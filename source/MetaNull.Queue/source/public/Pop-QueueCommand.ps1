<#
    .SYNOPSIS
        Remove a Command from the top or bottom of the queue
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [guid] $Id,
    
    [Parameter(Mandatory = $false)]
    [switch] $Unshift
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

        # Select which to remove
        if($Unshift.IsPresent -and $Unshift) {
            $Command = $Queue.Commands | Select-Object -First 1
        } else {
            $Command = $Queue.Commands | Select-Object -Last 1
        }

        # Find the commands
        if(-not $Command) {
            throw "No command found in queue $Id"
        }

        # Remove the command
        Write-Verbose "Removing command with index $($Command.Index) from queue $Id"
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $Command.RegistryKey | Remove-Item -Force
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }

        # Return the command (without the registry key, as it was deleted)
        $Command.RegistryKey = $null
        $Command | Write-Output
        
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}