<#
    .SYNOPSIS
        Add a new Command at the end of a queue
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [uid] $Id,

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
        if($Unique.IsPresent -and $Unique -and ($Queue.Commands | Where-Object { $_.Command -eq $Command })) {
            throw "Command already present in queue $Id"
        }

        # Find the last command index
        $LastCommandIndex = ($Queue.Commands | Sort-Object -Property Index | Select-Object -Last 1 | Select-Object -ExpandProperty Index) + 1

        # Create the new command
        $Properties = @{
            Index = $LastCommandIndex
            Command = $Command
            Name = $Name
        }

        # Add the new command to the registry
        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            $Item = New-Item "MetaNull:\Queues\$Id\Commands\$LastCommandIndex" -Force
            $Properties.GetEnumerator() | ForEach-Object {
                $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
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