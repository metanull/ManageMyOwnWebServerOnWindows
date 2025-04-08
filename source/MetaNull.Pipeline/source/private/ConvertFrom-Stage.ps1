<#
    .SYNOPSIS
#>
[CmdletBinding()]
[OutputType([System.Array])]
    param(
        [Parameter(Mandatory)]
        [guid]$PipelineId,

        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Stage,

        [string]$Name = 'Stage',

        [Parameter(Mandatory)]
        [System.Array]$StagePath,

        [bool]$Enabled = $true
    )
Process {
    # Step script's local variable name containing all inputs fro mthe pipeline
    $LocalVariableName = "$PipelineId.$Stage.$Job" -replace '\W','_'
    $LocalVariableValue = @{
        PipelineId = $PipelineId
        Stage = $Stage
        Name = $Name
        StagePath = $StagePath
        StageOutput = $null
        OldLocalValues = @{
            ErrorActionPreference = $null
            WarningPreference = $null
            DebugPreference = $null
            ExecutionPolicy = $null
            OutputEncoding = $null
        }
        Enabled = $Enabled
        LastExitCode = $null
        Success = 'Failed'
        Exception = $null
    } | ConvertTo-JSon -Compress -Depth 20


    # Generate the Script file
    $Script = @()
    $Script += "# ------------------------------------------------------------"
    $Script += "# $Name"
    $Script += "# Pipeline: $PipelineId"
    $Script += "# Stage:    $Stage"
    $Script += "# ------------------------------------------------------------"
    $Script += "# "
    $Script += "`$$LocalVariableName = '$LocalVariableValue' | ConvertFrom-JSon"
    $Script += "`$$LocalVariableName.OldLocalValues.ErrorActionPreference = `$ErrorActionPreference"
    $Script += "`$$LocalVariableName.OldLocalValues.WarningPreference = `$WarningPreference"
    $Script += "`$$LocalVariableName.OldLocalValues.DebugPreference = `$DebugPreference"
    $Script += "`$$LocalVariableName.OldLocalValues.ExecutionPolicy = (Get-ExecutionPolicy -Scope Process)"
    $Script += "`$$LocalVariableName.OldLocalValues.OutputEncoding = [Console]::OutputEncoding"
    $Script += "`$$LocalVariableName.StageOutput = @()"
    $Script += "try {"
    $Script += "    `$ErrorActionPreference = 'Stop'"
    $Script += "    `$WarningPreference = 'Continue'"
    $Script += "    `$DebugPreference = 'SilentlyContinue'"
    $Script += "    # ------------------------------------------------------------"
    $Script += "    `$StepFakeResult = `$$LocalVariableName | Select-Object PipelineId,Stage"
    $Script += "    `$StepFakeResult | Add-Member -MemberType NoteProperty -Name 'Job' -Value 1"
    $Script += "    `$StepFakeResult | Add-Member -MemberType NoteProperty -Name 'Success' -Value 'Failed'"
    $Script += "    `$StepFakeResult | Add-Member -MemberType NoteProperty -Name 'Exception' -Value `$null"
    $Script += "    # ------------------------------------------------------------"
    $Script += "    `$LastJobSuccess = 'Succeeded'"
    $Script += "    if(`$$LocalVariableName.Enabled) {"
    $Script += "        `$$LocalVariableName.StageOutput = `$$LocalVariableName.StagePath | Foreach-Object -Begin { `$StepIndex = 0 } -Process {"
    $Script += "            if(`$LastJobSuccess -in 'Canceled','Failed') {"
    $Script += "                `$StepFakeResult.Success = 'Canceled'"
    $Script += "                `$StepFakeResult | Write-Output"
    $Script += "                return"
    $Script += "            }"
    $Script += "            try {"
    $Script += "                `$$($LocalVariableName)_STDERR = `$null"
    $Script += "                `$$($LocalVariableName)_STDOUT = `$null"
    $Script += "                `$$($LocalVariableName)_STDWARN = `$null"
    $Script += "                `$InvokeCommandArguments = @{"
    $Script += "                    FilePath = `$_"
    $Script += "                    ErrorVariable = '$($LocalVariableName)_STDERR'"
    $Script += "                    WarningVariable = '$($LocalVariableName)_STDWARN'"
    $Script += "                    OutVariable = '$($LocalVariableName)_STDOUT'"
    $Script += "                }"
    $Script += "                Invoke-Command @InvokeCommandArguments" # 2>`$null 3>`$null # 2>&1
    $Script += "                `$LastJobSuccess = `$global:LAST_JOB_RESULT.Success"
    $Script += "                `$global:LAST_JOB_RESULT | Write-Output"
    $Script += "                return"
    $Script += "            } catch {"
    $Script += "                `$$LocalVariableName.Exception = `$_"
    $Script += "                `$$LocalVariableName.Success = 'Failed'"
    $Script += "                `$StepFakeResult.Success = `$$LocalVariableName.Success"
    $Script += "                `$StepFakeResult | Write-Output"
    $Script += "                return"
    $Script += "            }"
    $Script += "        }"
    $Script += "        `$$LocalVariableName.Success = `$$LocalVariableName.StageOutput | Select-Object -ExpandProperty 'Success' | Select-Object -Unique | Sort-Object {"
    $Script += "                switch(`$_){"                       # return the first status (in the following order)
    $Script += "                    'Failed' {1}"                   # If one of the Step failed (for any reason), Fail the whole
    $Script += "                    'Canceled' {2}"                 # If one of the Step cancelled, Fail the whole
    $Script += "                    'SucceededWithIssues' {3}"      # If at least one issue reported, return an Issue
    $Script += "                    'Succeeded' {4}"                # If all worked without
    $Script += "                    'Skipped' {5}"                  # Job was skipped (as it was disabled)
    $Script += "                    default {6}"                    # ???
    $Script += "                } | Select-Object -First 1"
    $Script += "            }"
    $Script += "    } else {"
    $Script += "        `$$LocalVariableName.Success = 'Skipped'"
    $Script += "    }"
    $Script += "    # ------------------------------------------------------------"
    $Script += "} finally {"
    $Script += "    `$global:LAST_STAGE_OUTPUT = `$$LocalVariableName"
    $Script += "    `$ErrorActionPreference = `$$LocalVariableName.OldLocalValues.ErrorActionPreference"
    $Script += "    `$WarningPreference = `$$LocalVariableName.OldLocalValues.WarningPreference"
    $Script += "    `$DebugPreference = `$$LocalVariableName.OldLocalValues.DebugPreference"
    $Script += "}"
    $Script += "# ------------------------------------------------------------"
    $Script | Write-Output
}