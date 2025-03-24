<#
.SYNOPSIS
    Run a step in the pipeline

.DESCRIPTION
    Run a step in the pipeline

.PARAMETER stepInput
    The input to the step (received from the pipeline definition)

.PARAMETER condition
    The condition to run the step (default: '$true -eq $true')

.PARAMETER continueOnError
    Continue on error (default: $false)

.PARAMETER displayName
    The display name of the step (default: 'Step 1')

.PARAMETER enabled
    Is the step enabled (default: $true)

.PARAMETER env
    The environment variables to set for the step (default: @{WHOAMI = $env:USERNAME})

.PARAMETER timeoutInMinutes
    The timeout for the step in minutes (default: 60)

.PARAMETER retryCountOnStepFailure
    The number of retries on step failure (default: 0)

.PARAMETER commands
    The commands to run in the step (default: 'return 0')

.PARAMETER variables
    The variables to set for the step (default: @{})

.PARAMETER StepOutput
    The output of the step

.EXAMPLE
    # Run a step
    $StepOutput = $null
    Invoke-Step -commands 'return 0' -StepOutput ([ref]$StepOutput)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [hashtable]$stepInput = @{args = @();path = '.'},
    [Parameter(Mandatory=$false)]
    [string]$condition = '$true -eq $true',
    [Parameter(Mandatory=$false)]
    [bool]$continueOnError = $false,
    [Parameter(Mandatory=$false)]
    [string]$displayName = 'Step 1',
    [Parameter(Mandatory=$false)]
    [bool]$enabled = $true,
    [Parameter(Mandatory=$false)]
    [hashtable]$env = @{WHOAMI = $env:USERNAME},
    [Parameter(Mandatory=$false)]
    [int]$timeoutInMinutes = 60,
    [Parameter(Mandatory=$false)]
    [int]$retryCountOnStepFailure = 0,
    [Parameter(Mandatory=$false)]
    [string[]]$commands = @(
        'return 0'
    ),
    [Parameter(Mandatory=$false)]
    [hashtable]$variables = @{},

    [Parameter(Mandatory)]
    [ref]$StepOutput
)
Process {
    # Print all arguments
    <#
        Write-Verbose "stepInput: "
        foreach ($key in $stepInput.Keys) {
            Write-Verbose "  $key = $($stepInput[$key])"
        }
        Write-Verbose "condition: $condition"
        Write-Verbose "continueOnError: $continueOnError"
        Write-Verbose "displayName: $displayName"
        Write-Verbose "enabled: $enabled"
        Write-Verbose "env: "
        foreach ($key in $env.Keys) {
            Write-Verbose "  $key = $($env[$key])"
        }
        Write-Verbose "STEP_ENV: "
        Get-ChildItem env: | where-object { $_.name -like 'STEP_*' } | foreach-object {
            Write-Verbose "  $($_.Name) = $($_.Value)"
        }
        Write-Verbose "timeoutInMinutes: $timeoutInMinutes"
        Write-Verbose "retryCountOnStepFailure: $retryCountOnStepFailure"
        Write-Verbose "commands: `n> $($commands -join "`n> ")"	
    #>

    # Initialize the step output
    $StepOutput.Value = [PSCustomObject]@{
        Variable = @()
        Result = @()
        Secret = @()
        Path = @()
    }

    # Set the variables
    foreach ($variable in $variables.Keys) {
        $StepOutput.Value.Variable += ,[pscustomobject]@{
            Name=$variable
            Value=$variables[$variable]
            IsSecret=$false
            IsOutput=$false
            IsReadOnly=$false
        }
    }

    # Ensure timeoutInMinutes is within the valid range, if not set to 5 minutes
    if ($timeoutInMinutes -le 0 -or $timeoutInMinutes -ge 1440) {
        $timeoutInMinutes = 5
    }

    # Check if the step should run (condition is true and step is enabled)
    $sb_condition = [scriptblock]::Create($condition)
    if (-not (& $sb_condition)) {
        Write-Warning "Step '$displayName' was skipped because the condition was false."
        return
    }
    if (-not $enabled) {
        Write-Warning "Step '$displayName' was skipped because it was disabled."
        return
    }

    # Set the environment variables
    [System.Environment]::SetEnvironmentVariable('STEP_CWD', (Resolve-Path $PSScriptRoot), [System.EnvironmentVariableTarget]::Process)
    foreach ($key in $env.Keys) {
        [System.Environment]::SetEnvironmentVariable(($key.ToUpper() -replace '\W','_'), $env[$key], [System.EnvironmentVariableTarget]::Process)
    }
    
    # Run the step
    $BackupErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Stop"
        
        # Create the scriptblocks
        # - Init: set-location
        $sb_init = [scriptblock]::Create("Set-Location $($stepInput.path)")
        # - Step: run the commands
        $sb_step = [scriptblock]::Create(($commands | Foreach-Object { 
            # Expand the variables
            $Command = $_
            $StepOutput.Value.Variable | Foreach-Object {
                $Command = $Command -replace "\$\($($_.Name)\)","$($_.Value)"
            }
            $Command | Write-Output
        }) -join "`n")
        
        # Run the step, optionally retrying on failure
        $Succeeded = $false
        do {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $job = Start-Job -ScriptBlock $sb_step -ArgumentList @($stepInput.args) -InitializationScript $sb_init 
                while ($job.State -eq 'Running') {
                    if($timer.Elapsed.TotalMinutes -gt $timeoutInMinutes) {
                        $retryCountOnStepFailure = 0
                        Stop-Job -Job $job  | Out-Null
                        $timer.Stop()
                        throw "Step exceeded the timeout of $timeoutInMinutes minutes and was terminated."
                    }
                    Receive-Job -Job $job -Wait:$false | Out-Vso -StepOutput ($StepOutput)
                    Start-Sleep -Seconds 1
                }
                Receive-Job -Job $job -Wait | Out-Vso -StepOutput ($StepOutput)
                $Succeeded = $true
                break
            } catch {
                Write-Warning "Step '$displayName' failed because of an Exception: $($_.Exception.Message)"
                # Disable retry on step failure caused by an exception
                $retryCountOnStepFailure = 0
            } finally {
                if($job) {
                    Stop-Job -Job $job  | Out-Null
                    Remove-Job -Job $job | Out-Null
                }
            }
        } while(($retryCountOnStepFailure --) -gt 0);

        # Set the steps result based on the success of the step, unless if set by the step itself
        if (-not $StepOutput.Value.Result) {
            $FinalResult = [pscustomobject]@{
                Message = 'Done'
                Result = 'Failed'
            }
            if($Succeeded) {
                $FinalResult.Result = 'Succeeded'
            } elseif ($continueOnError) {
                $FinalResult.Result = 'SucceededWithIssues'
            } else {
                $FinalResult.Result = 'Failed'
            }
            $StepOutput.Value.Result = $FinalResult
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
