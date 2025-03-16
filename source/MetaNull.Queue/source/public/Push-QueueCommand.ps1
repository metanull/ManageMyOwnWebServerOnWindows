<#
    .SYNOPSIS
        Add a new Command at the end of a queue
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return [guid]::TryParse($_, [ref]$ref)
    })]
    [string] $Id,

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
        # Find the queue
        $Queue = Get-Queue -Id $Id
        if(-not $Queue) {
            throw  "Queue $Id not found"
        }
        # Check if the command is already present
        if($Unique.IsPresent -and $Unique) {
            $ExistingCommand = $Queue.Commands | Where-Object { 
                $_.Command -eq $Command 
            }
            if($ExistingCommand) {
                Write-Warning "Command already present in queue $Id ($($ExistingCommand.Index) - $($ExistingCommand.Name))"
                # Return the command index
                return $ExistingCommand.Index
            }
        }

        # Add the new command
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $CommandIndex = $Queue.LastCommandIndex + 1
            $Item = New-Item -Path $Path -Name MetaNull.Queue.Command.$CommandIndex -Force
            $Properties = @{
                Index = $CommandIndex
                Command = $Command
                Name = $Name
                CreatedDate = (Get-Date|ConvertTo-Json)
            }
            $Properties.GetEnumerator() | ForEach-Object {
                $Item | New-ItemProperty -Name $_.Key -Value $_.Value -PropertyType $_.Value.GetType().Name | Out-Null
            }
            # Return the command
            return $CommandIndex
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}