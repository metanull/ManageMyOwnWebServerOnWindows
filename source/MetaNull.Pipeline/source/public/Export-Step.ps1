<#
    .SYNOPSIS
    Export a Step from a Pipeline to a Powershell script file
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
    $Step,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $OutputDirectory = $env:TEMP
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Item = Get-Item "MetaNull:\Pipelines\$Id\Stages\$($Stage)\Jobs\$($Job)\Steps\$($Step)"
        $Properties = $Item | Get-ItemProperty
        $Step = [pscustomobject]@{
            Index = $Properties.Index
            Name = $Properties.Name
            Commands = $Properties.Commands
            #Enabled = $Properties.Enabled
            #ContinueOnError = $Properties.ContinueOnError
            #TimeoutInSeconds = $Properties.TimeoutInSeconds
            #RetryCountOnStepFailure = $Properties.RetryCountOnStepFailure
        }

        # Create the Step file in `$OutputDirectory\`$PipeLineId\`$StageIndex\`$JobIndex and return its absolute path
        $StepFilePath = Join-Path -Path $OutputDirectory -ChildPath "$Id\$Stage\$Job\$Step.ps1"
        $StepScriptBlock = [scriptblock]::Create($Step.Commands -join "`n")
        $StepScriptBlock.ToString() | Set-Content -Path $StepFilePath -Force
        $StepFilePath | Write-Output

    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}
