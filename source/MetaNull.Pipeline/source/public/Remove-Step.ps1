<#
    .SYNOPSIS
    Remove a Step from a Pipeline
#>
[CmdletBinding()]
[OutputType([void])]
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
        $Item | Remove-Item -Recurse "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)\Steps\$($Step)" | Out-Null
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}