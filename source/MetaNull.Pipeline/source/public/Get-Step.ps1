<#
    .SYNOPSIS
    Remove a Step from a Pipeline
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('PipelineId')]
    [guid]
    $Id,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('StageIndex')]
    [int]
    $Stage,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('JobIndex')]
    [int]
    $Job,

    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
    [Alias('StepIndex')]
    [AllowNull()]
    [int]
    $Step = $null
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Get-ChildItem "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)\Steps" | Where-Object {
            $null -eq $step -or $_.Name -eq "$Step"
        } | ForEach-Object {
            $Properties = $_ | Get-ItemProperty
            [pscustomobject]@{
                Index = $Properties.Index
                Name = $Properties.Name
                Commands = $Properties.Commands
                #Enabled = $Properties.Enabled
                #ContinueOnError = $Properties.ContinueOnError
                #TimeoutInSeconds = $Properties.TimeoutInSeconds
                #RetryCountOnStepFailure = $Properties.RetryCountOnStepFailure
            } | Write-Output
        }
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}