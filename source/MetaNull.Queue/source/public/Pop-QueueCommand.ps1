<#
    .SYNOPSIS
        Remove a Command from the top or bottom of the queue
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return [guid]::TryParse($_, [ref]$ref)
    })]
    [string] $QueueId,
    
    [Parameter(Mandatory = $false)]
    [switch] $Unshift
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Commands = Get-QueueCommand -Scope $Scope -QueueId $QueueId -Name '*' | Sort-Object -Property Index
        if($Unshift.IsPresent -and $Unshift) {
            $Command = $Commands | Select-Object -First 1
        } else {
            $Command = $Commands | Select-Object -Last 1
        }

        if(-not $Command) {
            Write-Warning "No command found in queue $QueueId"
            return
        }
        
        # Remove the command
        Write-Verbose "Removing command with index $($Command.Index) from queue $QueueId"
        $Mutex = $null
        try {
            Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex) | Out-Null
            $Command.RegistryKey | Remove-Item -Force
        } finally {
            Unlock-ModuleMutex -Mutex ([ref]$Mutex) | Out-Null
        }

        # Return the command 
        $Command.RegistryKey = $null
        $Command | Write-Output
        
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}