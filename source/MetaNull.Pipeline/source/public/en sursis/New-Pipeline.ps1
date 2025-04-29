<#
    .SYNOPSIS
        Create a new pipeline object
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [string]
    $Id = [guid]::Empty.ToString(),

    [Parameter(Mandatory = $false)]
    [string]
    $Name = 'Pipeline',

    [Parameter(Mandatory = $false)]
    [string]
    $Description = 'Pipeline',

    [Parameter(Mandatory = $false)]
    [pscustomobject[]]
    $Stages = @()
)
Process {
    return [pscustomobject]@{
        Id = $Id
        Name = $Name
        Description = $Description
        Stages = $Stages
        
        Trigger = 'main'
        Pool = 'vmImage: ''windows-latest'''
    } | Write-Output
}