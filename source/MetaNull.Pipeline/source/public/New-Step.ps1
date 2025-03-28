<#
    .SYNOPSIS
    Add a step to a pipeline
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
    [string]
    $Name = 'Step',

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string[]]
    $Commands,

    [Parameter(Mandatory = $false)]
    [switch]
    $Enabled,

    [Parameter(Mandatory = $false)]
    [switch]
    $ContinueOnError,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 86400)]
    [int]
    $TimeoutInSeconds = 300,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]
    $RetryCountOnStepFailure = 0
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if( -not (Test-Path "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)")) {
            throw "Could not find the specified Pipeline, Stage, or Job"
        }
        $LastStepIndex = Get-ChildItem -Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Steps" | Foreach-Object {
            $_ | Get-ItemProperty -Name Index | Select-Object -ExpandProperty Value
        } | Sort-Object | Select-Object -Last 1
        $LastStepIndex ++

        $Item = New-Item "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)\Steps\$($LastStepIndex)"
        $Item | Set-ItemProperty -Name Index -Value $LastStepIndex
        $Item | Set-ItemProperty -Name Name -Value $Name
        $Item | Set-ItemProperty -Name Commands -Value $Commands
        #$Enabled = $true
        #if($Enabled.IsPresent -and -not $Enabled) {
        #    $Enabled = $false
        #}
        #$ContinueOnError = $true
        #if($ContinueOnError.IsPresent -and -not $ContinueOnError) {
        #    $ContinueOnError = $false
        #}
        #$Item | Set-ItemProperty -Name Enabled -Value $Enabled
        #$Item | Set-ItemProperty -Name ContinueOnError -Value $ContinueOnError
        #$Item | Set-ItemProperty -Name TimeoutInSeconds -Value $TimeoutInSeconds
        #$Item | Set-ItemProperty -Name RetryCountOnStepFailure -Value $RetryCountOnStepFailure
        $LastStepIndex | Write-Output
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}