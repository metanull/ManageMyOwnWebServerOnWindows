<#
    .SYNOPSIS
        Create a new job object
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [string]$Name = 'Job',
    
    [Parameter(Mandatory = $false)]
    [pscustomobject[]]$Steps = @()
)
Process {
    return [pscustomobject]@{
        Name = $Name
        Steps = $Steps
    } | Write-Output
}