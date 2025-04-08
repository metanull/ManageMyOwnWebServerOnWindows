<#
    .SYNOPSIS
        
#>
[CmdletBinding()]
[OutputType([System.Array])]
    param(
        [Parameter(Mandatory)]
        [guid]$PipelineId,

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Stage,

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Job,

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Step,

        [Parameter(Mandatory)]
        [System.Array]$Commands,

        [Parameter(Mandatory)]
        $LocalWorkingDirectory,

        [bool]$Enabled = $true,

        [string]$Name = 'Step',

        [ValidateSet('Continue','SilentlyContinue','Stop')]
        [string]$LocalErrorActionPreference = 'Stop',
        [ValidateSet('Continue','SilentlyContinue','Stop')]
        [string]$LocalDebugPreference = 'SilentlyContinue',
        [ValidateSet('Continue','SilentlyContinue','Stop')]
        [string]$LocalWarningPreference = 'Continue',
        [bool]$LocalFailOnStderr = $true,
        [hashtable]$LocalEnvironment = [hashtable]::Empty,
        [hashtable]$LocalInputs = [hashtable]::Empty,
        [hashtable]$LocalVariables = [hashtable]::Empty
    )
Process {
    # Step script's local variable name containing all inputs fro mthe pipeline
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
        Enabled = $Enabled
        LastExitCode = $null
        ScriptBlock = @()
        Success = 'Failed'
        Exception = $null
        ScriptBlockOffset = 0
    } | ConvertTo-JSon -Compress -Depth 20

    # Perform Variable Expansion on the Step's commands
    $ExpandedCommands = $Commands | Foreach-Object -Begin { 
            $CommandIndex = 0 
            $ExpandableVariables = $LocalVariables | Format-Hashtable -Format 'Flat'
            $VariableExpansionExpression = [regex]::new('(?<needle>\$\((?<variable>.*?)\))')
        } -Process {
            $CommandIndex ++
            # Perform Variable Expansion
            $ExpressionResult = $VariableExpansionExpression.Match($_)
            if(($ExpressionResult.Groups['needle'].Success)) {
                $Needle = $ExpressionResult.Groups['needle'].Value
                $Expansion = $ExpandableVariables[$ExpressionResult.Groups['variable'].Trim()]
                $_.Replace($Needle,$Expansion) | Write-Output
            } else {
                $_ | Write-Output
            }
        }

    # Generate the Script file
    $Script = @()
    $Script += "# ------------------------------------------------------------"
    $Script += "# $Name"
    $Script += "# Pipeline: $PipelineId"
    $Script += "# Stage:    $Stage"
    $Script += "# Job:      $Job"
    $Script += "# Step:     $Step"
    $Script += "# ------------------------------------------------------------"
    $Script += "# "
    $Script += "`$$LocalVariableName = '$LocalVariableValue' | ConvertFrom-JSon"
    $Script += "`$$LocalVariableName.ScriptBlock = {"
    $Script += "    $($ExpandedCommands -join "`n    ")"
    $Script += "}"
    $Script += "if(`$LocalEnvironment -is [hashtable] -and `$LocalEnvironment -ne [hashtable]::Empty) {"
    $Script += "    `$LocalEnvironment | Foreach-Object {"
    $Script += "        `$_.GetEnumerator() | Foreach-Object {"
    $Script += "            [System.Environment]::SetEnvironmentVariable(`$_.Key,`$_.Value,[System.EnvironmentVariableTarget]::Process)"
    $Script += "        }"
    $Script += "    }"
    $Script += "}"
    $Script += "`$$LocalVariableName.OldLocalValues.ErrorActionPreference = `$ErrorActionPreference"
    $Script += "`$$LocalVariableName.OldLocalValues.WarningPreference = `$WarningPreference"
    $Script += "`$$LocalVariableName.OldLocalValues.DebugPreference = `$DebugPreference"
    $Script += "`$$LocalVariableName.OldLocalValues.ExecutionPolicy = (Get-ExecutionPolicy -Scope Process)"
    $Script += "`$$LocalVariableName.OldLocalValues.OutputEncoding = [Console]::OutputEncoding"
    $Script += "try {"
    $Script += "    `$global:LASTEXITCODE = 0"
    $Script += "    `$ErrorActionPreference = '$($LocalErrorActionPreference)'"
    $Script += "    `$WarningPreference = '$($LocalWarningPreference)'"
    $Script += "    `$DebugPreference = '$($LocalDebugPreference)'"
    $Script += "    Set-ExecutionPolicy 'Bypass' -Scope Process"
    $Script += "    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8"
    $Script += "    Push-Location '$($LocalWorkingDirectory | Select-EscapeSingleQuotedString)'"
    $Script += "    # ------------------------------------------------------------"
    $Script += "    if(`$$LocalVariableName.Enabled) {"
    $Script += "        try {"
    $Script += "            `$$($LocalVariableName)_STDERR = `$null"
    $Script += "            `$$($LocalVariableName)_STDOUT = `$null"
    $Script += "            `$$($LocalVariableName)_STDWARN = `$null"
    $Script += "            `$$LocalVariableName.ScriptBlockOffset = $($Script.Count)"
    $Script += "            `$InvokeCommandArguments = @{"
    $Script += "                ScriptBlock = `$$LocalVariableName.ScriptBlock"
    $Script += "                ErrorVariable = '$($LocalVariableName)_STDERR'"
    $Script += "                WarningVariable = '$($LocalVariableName)_STDWARN'"
    $Script += "                OutVariable = '$($LocalVariableName)_STDOUT'"
    $Script += "            }"
    $Script += "            Invoke-Command @InvokeCommandArguments" # 2>`$null 3>`$null # 2>&1
    $Script += "            if(`$null -ne `$LASTEXITCODE -and `$LASTEXITCODE -ne 0) {"
    $Script += "                `$$LocalVariableName.LastExitCode = `$LASTEXITCODE"
    $Script += "                `$$LocalVariableName.Success = 'Failed'"
    $Script += "            } elseif(`$$($LocalVariableName)_STDERR) {"
    $Script += "                if(`$$LocalVariableName.FailOnStderr) {"
    $Script += "                    `$$LocalVariableName.Success = 'Failed'"
    $Script += "                } else {"
    $Script += "                    `$$LocalVariableName.Success = 'SucceededWithIssues'"
    $Script += "                }"
    $Script += "            } else {"
    $Script += "                `$$LocalVariableName.Success = 'Succeeded'"
    $Script += "            }"
    $Script += "        } catch {"
    $Script += "            `$$LocalVariableName.Exception = `$_"
    $Script += "            `$$LocalVariableName.Success = 'Failed'"
    $Script += "        }"
    $Script += "    } else {"
    $Script += "        `$$LocalVariableName.Success = 'Skipped'"
    $Script += "    }"
    $Script += "    # ------------------------------------------------------------"
    $Script += "} finally {"
    $Script += "    `$global:LAST_STEP_RESULT = `$$LocalVariableName"
    $Script += "    Pop-Location"
    $Script += "    `$ErrorActionPreference = `$$LocalVariableName.OldLocalValues.ErrorActionPreference"
    $Script += "    `$WarningPreference = `$$LocalVariableName.OldLocalValues.WarningPreference"
    $Script += "    `$DebugPreference = `$$LocalVariableName.OldLocalValues.DebugPreference"
    $Script += "    Set-ExecutionPolicy `$$LocalVariableName.OldLocalValues.ExecutionPolicy -Scope Process"
    $Script += "    [Console]::OutputEncoding = `$$LocalVariableName.OldLocalValues.OutputEncoding"
    $Script += "}"
    $Script += "# ------------------------------------------------------------"
    
    $Script | Write-Output
}