<#
    .SYNOPSIS
        Get the Command(s) in a Queue, sorted by their number
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
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

    [Parameter(Mandatory = $false, Position = 1)]
    [string] $Name = '*'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Get-Queue -QueueId $QueueId | Select-Object -ExpandProperty Commands | Where-Object { 
            $null -eq $Name -or $_.Name -like $Name
        } | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}