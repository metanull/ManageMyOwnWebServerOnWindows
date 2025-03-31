<#
    .SYNOPSIS
        Create a new job object
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000)]
    [int]$Job = 1,
    
    [Parameter(Mandatory = $false)]
    [string]$Name = 'Job',
    
    [Parameter(Mandatory = $false)]
    [pscustomobject[]]$Steps = @()
)
Process {
    return [pscustomobject]@{
        Job = $Job
        Name = $Name
        Steps = $Steps
    } | Write-Output
}