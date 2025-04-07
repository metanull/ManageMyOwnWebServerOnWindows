<#
    .SYNOPSIS
        Write the pipleine to a set of script files
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
Begin {
    Function ConvertTo-EscapedCommand {
        param(
            [Parameter(Mandatory,ValueFromPipeline)]
            [AllowNull()]
            [AllowEmptyString()]
            [string] $String
        )
        if($String) {
            [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($String)
        }
    }

    Function ConvertTo-StepCode {
        param(
            [Parameter(Mandatory)]
            [guid]$PipelineId,

            [Parameter(Mandatory)]
            [ValidateRange(0, [int]::MaxValue)]
            [int]$Stage,

            [Parameter(Mandatory)]
            [ValidateRange(0, [int]::MaxValue)]
            [int]$Job,

            [Parameter(Mandatory)]
            [ValidateRange(0, [int]::MaxValue)]
            [int]$Step,

            [string]$Name = 'Step',

            [Parameter(Mandatory)]
            [System.Array]$Commands,

            [Parameter(Mandatory)]
            $LocalWorkingDirectory,
            [ValidateSet('Continue','SilentlyContinue','Stop')]
            [string]$LocalErrorActionPreference = 'Stop',
            [bool]$LocalFailOnStderr = $true,
            [hashtable]$LocalEnvironment = [hashtable]::Empty,
            [hashtable]$LocalInputs = [hashtable]::Empty,
            [hashtable]$LocalVariables = [hashtable]::Empty
        )
        $LocalVariableName = "$PipelineId.$Stage.$Job.$Step" -replace '\W','_'
        $LocalVariableValue = @{
            PipelineId = $PipelineId
            Stage = $Stage
            Job = $Job
            Step = $Step
            Name = $Name
            ErrorActionPreference = $LocalErrorActionPreference
            FailOnStderr = $LocalFailOnStderr
            Environment = $LocalEnvironment
            Inputs = $LocalInputs
            Variables = $LocalVariables
            WorkingDirectory = $LocalWorkingDirectory
            OldLocalValues = @{
                ErrorActionPreference = $null
                WarningPreference = $null
                DebugPreference = $null
                ExecutionPolicy = $null
                OutputEncoding = $null
            }
            LastExitCode = $null
            ScriptBlock = @()
            Success = 'Failed'
            Exception = $null
            ScriptBlockOffset = 0
        } | ConvertTo-JSon -Compress -Depth 20

        $Script = @()
        $Script += "# ------------------------------------------------------------"
        $Script += "# $Name"
        $Script += "# Pipeline: $PipelineId"
        $Script += "# Stage:    $Stage"
        $Script += "# Job:      $Job"
        $Script += "# Step:     $Step"
        $Script += "# ------------------------------------------------------------"
        $Script += "# "
        # Step's state
        $Script += "`$$LocalVariableName = '$LocalVariableValue' | ConvertFrom-JSon"
        # Step's environment
        $Script += "`$$LocalVariableName.ScriptBlock = {"
            $Commands | Foreach-Object -Begin { $CommandIndex = 0 } -Process {
                $CommandIndex ++
                $Script += $_
            }
        $Script += "}"
        #$Script += "`$$LocalVariableName.Environment | Foreach-Object { `$_.GetEnumerator() | Foreach-Object { [System.Environment]::SetEnvironmentVariable(`$_.Key,`$_.Value,[System.EnvironmentVariableTarget]::Process) }}"
        $Script += "`$$LocalVariableName.OldLocalValues.ErrorActionPreference = `$ErrorActionPreference"
        $Script += "`$$LocalVariableName.OldLocalValues.WarningPreference = `$WarningPreference"
        $Script += "`$$LocalVariableName.OldLocalValues.DebugPreference = `$DebugPreference"
        $Script += "`$$LocalVariableName.OldLocalValues.ExecutionPolicy = (Get-ExecutionPolicy -Scope Process)"
        $Script += "`$$LocalVariableName.OldLocalValues.OutputEncoding = [Console]::OutputEncoding"
        $Script += "try {"
            $Script += "`$global:LASTEXITCODE = 0"
            $Script += "`$ErrorActionPreference = '$($LocalErrorActionPreference)'"
            $Script += "`$WarningPreference = 'Continue'"
            $Script += "`$DebugPreference = 'SilentlyContinue'"
            $Script += "Set-ExecutionPolicy 'Bypass' -Scope Process"
            $Script += "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8"
            $Script += "Push-Location '$($LocalWorkingDirectory | ConvertTo-EscapedCommand)'"
            $Script += "# ------------------------------------------------------------"
            $Script += "try {"
                $Script += "`$$($LocalVariableName)_STDERR = `$null"
                $Script += "`$$($LocalVariableName)_STDOUT = `$null"
                $Script += "`$$($LocalVariableName)_STDWARN = `$null"
                $Script += "`$$LocalVariableName.ScriptBlockOffset = $($Script.Count)"
                # $Script += "Invoke-Command -ScriptBlock `$$LocalVariableName.ScriptBlock -ArgumentList `$$LocalVariableName.Inputs,`$$LocalVariableName.Environment -ErrorVariable LocalStdErr 2>&1"
                # $Script += "Invoke-Command -ScriptBlock `$$LocalVariableName.ScriptBlock -ErrorVariable $($LocalVariableName)_STDERR -WarningVariable $($LocalVariableName)_STDWARN -OutVariable $($LocalVariableName)_STDOUT 2>`$null 3>`$null"
                $Script += "`$InvokeCommandArguments = @{"
                $Script += "ScriptBlock = `$$LocalVariableName.ScriptBlock"
                $Script += "ErrorVariable = '$($LocalVariableName)_STDERR'"
                $Script += "WarningVariable = '$($LocalVariableName)_STDWARN'"
                $Script += "OutVariable = '$($LocalVariableName)_STDOUT'"
                $Script += "}"
                $Script += "Invoke-Command @InvokeCommandArguments"
                $Script += "if(`$null -ne `$LASTEXITCODE -and `$LASTEXITCODE -ne 0) {"
                    $Script += "`$$LocalVariableName.LastExitCode = `$LASTEXITCODE"
                    $Script += "`$$LocalVariableName.Success = 'Failed'"
                $Script += "} elseif(`$$($LocalVariableName)_STDERR) {"
                    $Script += "if(`$$LocalVariableName.FailOnStderr) {"
                        $Script += "`$$LocalVariableName.Success = 'Failed'"
                    $Script += "} else {"
                        $Script += "`$$LocalVariableName.Success = 'SucceededWithIssues'"
                    $Script += "}"
                $Script += "} else {"
                    $Script += "`$$LocalVariableName.Success = 'Succeeded'"
                $Script += "}"
            $Script += "} catch {"
                $Script += "`$$LocalVariableName.Exception = `$_"
                $Script += "`$$LocalVariableName.Success = 'Failed'"
            $Script += "}"
            $Script += "# ------------------------------------------------------------"
        $Script += "} finally {"
            $Script += "`$global:LAST_STEP_RESULT = `$$LocalVariableName"
            $Script += "Pop-Location"
            $Script += "`$ErrorActionPreference = `$$LocalVariableName.OldLocalValues.ErrorActionPreference"
            $Script += "`$WarningPreference = `$$LocalVariableName.OldLocalValues.WarningPreference"
            $Script += "`$DebugPreference = `$$LocalVariableName.OldLocalValues.DebugPreference"
            $Script += "Set-ExecutionPolicy `$$LocalVariableName.OldLocalValues.ExecutionPolicy -Scope Process"
            $Script += "[Console]::OutputEncoding = `$$LocalVariableName.OldLocalValues.OutputEncoding"
        $Script += "}"
        $Script += "# ------------------------------------------------------------"
        $Script | Write-Output
    }
}
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
                $Job.Steps | Foreach-Object -Begin { $StepIndex = 0 } -Process {
                    $Step = $_
                    $StepIndex ++
                    #$Step.Name
                    $StepDirectory = Join-Path $JobDirectory $StepIndex.ToString()
                    New-Item -Path $StepDirectory -ItemType Directory | Out-Null
                    $StepFile = Join-Path $StepDirectory "Step.ps1"
                    ConvertTo-StepCode -PipelineId $Pipeline.Id -Stage $StageIndex -Job $JobIndex -Step $StepIndex -Name $Step.Name `
                        -Commands $Step.Commands `
                        -LocalWorkingDirectory $Env:TEMP `
                        -LocalErrorActionPreference 'Stop' `
                        -LocalFailOnStderr $true `
                        -LocalEnvironment @{} `
                        -LocalInputs @{} `
                        -LocalVariables @{} `
                        | Out-File -FilePath $StepFile
                }
            }
        }
        Get-Item $PipelineFile | Write-Output
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}
