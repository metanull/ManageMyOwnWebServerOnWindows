<#
    .SYNOPSIS
    Test existance of a Step from a Pipeline
#>
[CmdletBinding()]
[OutputType([bool])]
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
        return Test-Path "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)\Steps\$($Step)"
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}