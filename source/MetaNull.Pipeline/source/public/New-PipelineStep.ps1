<#
    .SYNOPSIS
        Create a new step object
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000)]
    [int]$Step = 1,
    
    [Parameter(Mandatory = $false)]
    [string]$Name = 'Step',
    
    [Parameter(Mandatory = $false)]
    [string[]]$Commands = @(),
    
    [ValidateSet('Continue', 'Stop', 'SilentlyContinue')]
    [string]
    $ErrorPreference = 'Stop',

    [Parameter(Mandatory = $false)]
    [bool]
    $FailOnStderr = $true,

    [Parameter(Mandatory = $false)]
    [hashtable]
    $Env = @{}
)
Process {
    return [pscustomobject]@{
        Step = $Step
        Name = $Name
        Commands = $Commands

        TargetType = 'inline'
        Pwsh = $true
        WorkingDirectory = '$Build.SourcesDirectory'
        ErrorActionPreference = $ErrorPreference
        FailOnStderr = $FailOnStderr
        Env = $Env
    } | Write-Output
}
