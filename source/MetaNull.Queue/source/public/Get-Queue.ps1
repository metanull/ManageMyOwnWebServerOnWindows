<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [AllowNull()]
    [AllowEmptyString()]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return $null -eq $_ -or $_ -eq [string]::empty -or ([guid]::TryParse($_, [ref]$ref))
    })]
    [string] $QueueId = $null
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Find-Queue -Scope $Scope -Name * | Where-Object { 
            $null -eq $QueueId -or $QueueId -eq [string]::empty -or $_.QueueId -eq $QueueId
        } | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
