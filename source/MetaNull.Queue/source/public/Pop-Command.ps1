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

    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
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
        Get-Queue -QueueId $QueueId | ForEach-Object {
            if($_.Commands.Count -eq 0) {
                Write-Warning "Queue $QueueId is empty"
                return
            }
            if($Unshift.IsPresent -and $Unshift) {
                $Command = $_.Commands | Sort-Object -Property Index | Select-Object -First 1
            } else {
                $Command = $_.Commands | Sort-Object -Property Index -Descending | Select-Object -First 1
            }

            # Remove the command
            Write-Verbose "Removing command with index $($Command.Index) from queue $QueueId"
            $Mutex = $null
            try {
                Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex)
                $Command.RegistryKey | Remove-Item -Force
            } finally {
                Unlock-ModuleMutex -Mutex ([ref]$Mutex)
            }
            # Return the command
            $Command | Write-Output
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}