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

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
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
        $Queue = Get-Queue -QueueId $QueueId
        if(-not $Queue) {
            throw  "Queue $QueueId not found"
        }
        
        if($Unique.IsPresent -and $Unique) {
            $ExistingCommand = $Queue.Commands | Where-Object { 
                $Queue.Command -eq $Command 
            }
            if($ExistingCommand) {
                Write-Warning "Command already present in queue $QueueId ($($ExistingCommand.Index) - $($ExistingCommand.Name))"
                # Return the command index
                return $ExistingCommand.Index
            }
        }

        # Add the new command
        $CommandIndex = $Queue.LastCommandIndex + 1
        Write-Verbose "Adding command with index $CommandIndex to queue $QueueId"
        $Path = Join-Path -Path $_.RegistryKey.PSPath $ChildPath 'Commands' -Resolve

        $Mutex = $null
        try {
            Lock-ModuleMutex -Name 'QueueReadWrite' -Mutex ([ref]$Mutex)
            $Item = New-Item -Path $Path -Name "$($CommandIndex)"
            $Item | New-ItemProperty -Name Name -Value $Name -PropertyType String | Out-Null
            $Item | New-ItemProperty -Name Command -Value $Command -PropertyType String | Out-Null
            $Item | New-ItemProperty -Name CreatedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null

            # Return the command
            return $CommandIndex
        } finally {
            Unlock-ModuleMutex -Mutex ([ref]$Mutex)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}