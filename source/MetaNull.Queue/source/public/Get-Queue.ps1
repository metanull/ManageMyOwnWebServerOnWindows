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
    [ValidateScript({ 
        $ref = [guid]::Empty
        return $null -eq $_ -or ([guid]::TryParse($_, [ref]$ref))
    })]
    [string] $QueueId
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Find-Queue -Scope $Scope -Name * | Where-Object { 
            if($QueueId) {
                $_.QueueId -eq $QueueId
            } else {
                $true
            }
        } | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
