<#
    .SYNOPSIS
        Create a new stage object
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [string]$Name = 'Stage',
    
    [Parameter(Mandatory = $false)]
    [pscustomobject[]]$Jobs = @()
)
Process {
    return [pscustomobject]@{
        Name = $Name
        Jobs = $Jobs
    } | Write-Output
}