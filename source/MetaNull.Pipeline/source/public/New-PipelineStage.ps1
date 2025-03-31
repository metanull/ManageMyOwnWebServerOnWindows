<#
    .SYNOPSIS
        Create a new stage object
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000)]
    [int]$Stage = 1,
    
    [Parameter(Mandatory = $false)]
    [string]$Name = 'Stage',
    
    [Parameter(Mandatory = $false)]
    [pscustomobject[]]$Jobs = @()
)
Process {
    return [pscustomobject]@{
        Stage = $Stage
        Name = $Name
        Jobs = $Jobs
    } | Write-Output
}