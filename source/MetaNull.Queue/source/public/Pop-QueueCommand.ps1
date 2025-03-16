<#
    .SYNOPSIS
        Remove a Command from the top or bottom of the queue
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return [guid]::TryParse($_, [ref]$ref)
    })]
    [string] $Id,
    
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
        $Commands = $Queue.Commands
        if(-not $Commands) {
            Write-Warning "No command found in queue $Id"
            return
        }

        # Select which to remove
        if($Unshift.IsPresent -and $Unshift) {
            $Command = $Commands | Select-Object -First 1
        } else {
            $Command = $Commands | Select-Object -Last 1
        }
        
        $Command.RegistryKey | Write-Warning

        # Remove the command
        Write-Verbose "Removing command with index $($Command.Index) from queue $Id"
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $Command.RegistryKey | Remove-Item -Force
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }

        # Return the command 
        $Command.RegistryKey = $null
        $Command | Write-Output
        
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}