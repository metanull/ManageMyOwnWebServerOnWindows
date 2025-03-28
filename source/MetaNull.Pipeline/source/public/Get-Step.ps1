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

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('StepIndex')]
    [int]
    $Step
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Item = Get-Item "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)\Steps\$($Step)"
        $Properties = $Item | Get-ItemProperty
        [pscustomobject]@{
            Index = $Properties.Index
            Name = $Properties.Name
            Commands = $Properties.Commands
            #Enabled = $Properties.Enabled
            #ContinueOnError = $Properties.ContinueOnError
            #TimeoutInSeconds = $Properties.TimeoutInSeconds
            #RetryCountOnStepFailure = $Properties.RetryCountOnStepFailure
        }
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}