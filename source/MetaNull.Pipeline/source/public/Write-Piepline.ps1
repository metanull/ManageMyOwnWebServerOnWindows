<#
    .SYNOPSIS
        Write the pipeline to a set of script files
#>
[CmdletBinding()]
[OutputType([System.IO.DirectoryInfo])]
# [OutputType([System.Array])]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [pscustomobject]
    $Pipeline,

    [Parameter(Mandatory, Position = 1)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = "$($Env:TEMP)\MetaNull\Pipeline"
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $PipelineDirectory = Join-Path $OutputDirectory $Pipeline.Id.ToString()
        $PipelineFile = Join-Path $PipelineDirectory "Pipeline.ps1"
        New-Item -Path $PipelineDirectory -ItemType Directory | Out-Null
        $Pipeline.Stages | Foreach-Object -Begin { $StageIndex = 0 } -Process {
            $Stage = $_
            $StageIndex ++
            # $Stage.Name
            $StageDirectory = Join-Path $PipelineDirectory $StageIndex.ToString()
            New-Item -Path $StageDirectory -ItemType Directory | Out-Null
            $StageFile = Join-Path $StageDirectory "Stage.ps1"

            $Stage.Jobs | Foreach-Object -Begin { $JobIndex = 0 } -Process {
                $Job = $_
                $JobIndex ++
                #$Job.Name
                $JobDirectory = Join-Path $StageDirectory $JobIndex.ToString()
                New-Item -Path $JobDirectory -ItemType Directory | Out-Null
                $JobFile = Join-Path $JobDirectory "Job.ps1"
                $JobStepFiles = $Job.Steps | Foreach-Object -Begin { $StepIndex = 0 } -Process {
                    $Step = $_
                    $StepIndex ++
                    #$Step.Name
                    $StepDirectory = Join-Path $JobDirectory $StepIndex.ToString()
                    New-Item -Path $StepDirectory -ItemType Directory | Out-Null
                    $StepFile = Join-Path $StepDirectory "Step.ps1"
                    ConvertFrom-Step -PipelineId $Pipeline.Id -Stage $StageIndex -Job $JobIndex -Step $StepIndex -Name $Step.Name `
                        -Commands $Step.Commands `
                        -Enabled $true `
                        -LocalWorkingDirectory $Env:TEMP `
                        -LocalErrorActionPreference 'Stop' `
                        -LocalFailOnStderr $true `
                        -LocalEnvironment @{A = 'a'; B = 'B'} `
                        -LocalInputs @{Inp1 = 'One'} `
                        -LocalVariables @{Rav = 'Var'; Var = 'Rav'} `
                        | Out-File -FilePath $StepFile

                    $StepFile | Write-Output
                }
                ConvertFrom-Code  -PipelineId $Pipeline.Id -Stage $StageIndex -Job $JobIndex -Name $Job.Name `
                    -StepPath = $JobStepFiles.FullName
            }
        }
        Get-Item $PipelineFile | Write-Output
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}
