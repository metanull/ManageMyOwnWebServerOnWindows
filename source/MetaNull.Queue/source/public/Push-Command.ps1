<#
    .SYNOPSIS
        Add a new Command at the end of a queue
#>
[CmdletBinding()]
[OutputType([int])]
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

    [Parameter(Mandatory, Position = 1)]
    [string] $Command,

    [Parameter(Mandatory = $false, Position = 2)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $Name,
    
    [Parameter(Mandatory = $false)]
    [switch] $Unique
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Get-Queue -QueueId $QueueId | ForEach-Object {
            if($Unique.IsPresent -and $Unique) {
                $ExistingCommand = $_.Commands | Where-Object { 
                        $_.Command -eq $Command 
                    }
                if($ExistingCommand) {
                    Write-Warning "Command already present in queue $QueueId ($($ExistingCommand.Index) - $($ExistingCommand.Name))"
                    return
                }
            }

            # Add the new command
            $CommandIndex = $_.LastCommandIndex + 1
            Write-Verbose "Adding command with index $CommandIndex to queue $QueueId"
            $Path = Join-Path -Path $_.RegistryKey.PSPath $ChildPath 'Commands' -Resolve
            $Mutex = $null
            try {
                Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex)
                $Item = New-Item -Path $Path -Name "$CommandIndex"
                $Item | New-ItemProperty -Name Name -Value $Name -PropertyType String | Out-Null
                $Item | New-ItemProperty -Name Command -Value $Command -PropertyType String | Out-Null
                $Item | New-ItemProperty -Name CreatedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null
            } finally {
                Unlock-ModuleMutex -Mutex ([ref]$Mutex)
            }
            # Return the command index
            $CommandIndex | Write-Output
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}