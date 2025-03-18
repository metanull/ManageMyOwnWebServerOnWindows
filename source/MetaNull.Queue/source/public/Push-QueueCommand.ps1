<#
    .SYNOPSIS
        Add a new Command at the end of a queue
#>
[CmdletBinding(DefaultParameterSetName='REG_MULTI_SZ')]
[OutputType([int])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [guid] $Id,

    [Parameter(Mandatory, Position = 1, ParameterSetName = 'REG_MULTI_SZ')]
    [string[]] $Commands,

    [Parameter(Mandatory, Position = 1, ParameterSetName = 'REG_SZ')]
    [string[]] $Command,

    [Parameter(Mandatory, Position = 1, ParameterSetName = 'REG_EXPAND_SZ')]
    [string[]] $ExpandableCommand,

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
    
    [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
    try {
        # Collect the existing commands
        $CommandList = [object[]](Get-ChildItem "MetaNull:\Queues\$Id\Commands" -ErrorAction SilentlyContinue | Foreach-Object {
            $_ | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* | Write-Output
        } | Sort-Object -Property Index)

        # Check if the command is already present
        if($Unique.IsPresent -and $Unique -and ($Commands | Where-Object { $_.Command -eq $Command })) {
            throw "Command already present in queue $Id"
        }

        # Find the last command index
        $LastCommandIndex = ($CommandList | Select-Object -Last 1 | Select-Object -ExpandProperty Index) + 1

        # Create the new command
        $Properties = @{
            Index = $LastCommandIndex
            Name = $Name
            # Command = $Command    # This value is set separately, as it allows different types (REG_SZ, REG_MULTI_SZ, REG_EXPAND_SZ)
        }

        # Add the new command to the registry
        $Item = New-Item "MetaNull:\Queues\$Id\Commands\$LastCommandIndex" -Force
        switch($PSCmdlet.ParameterSetName) {
            'REG_EXPAND_SZ' {
                $Item | New-ItemProperty -Name Command -Value $ExpandableCommand -Type ExpandString | Out-Null
            }
            'REG_SZ' {
                $Item | New-ItemProperty -Name Command -Value $Command -Type String | Out-Null
            }
            default {
                $Item | New-ItemProperty -Name Command -Value ([string[]]$Commands) -Type MultiString | Out-Null
            }
        }
        $Properties.GetEnumerator() | ForEach-Object {
            $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
        }

        # Return the command Index
        return $LastCommandIndex
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}