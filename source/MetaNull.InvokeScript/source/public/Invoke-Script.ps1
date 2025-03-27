<#
.SYNOPSIS
    Invoke a script, defined as an array of strings

.DESCRIPTION
    Invoke a script, defined as an array of strings
    (Purpose: Run a step from a pipeline)

.PARAMETER Commands
    The Commands to run in the step
    @("'Hello World' | Write-Output"), for example

.PARAMETER ScriptInputs
    The input to the script (optional arguments received from the pipeline definition) (default: @{})
    @{args = @(); path = '.'}, for example

.PARAMETER ScriptEnvironment
    The environment ScriptVariables to set for the step (default: @{})
    They are added to the script's local environment
    @{WHOAMI = $env:USERNAME}, for example

.PARAMETER ScriptVariables
    The ScriptVariables to set for the step (default: @{})
    They are used to expand variables in the Commands. Format of the variable is $(VariableName)
    @{WHOAMI = 'Pascal Havelange'}, for example

.PARAMETER DisplayName
    The display name of the step (default: 'MetaNull.Invoke-Script')

.PARAMETER Enabled
    Is the step Enabled (default: $true)

.PARAMETER Condition
    The Condition to run the step (default: '$true -eq $true')

.PARAMETER ContinueOnError
    Continue on error (default: $false)
    If set to true, in case of error, the result will indicate that the step has 'completed with issues' instead of 'failed'

.PARAMETER TimeoutInMinutes
    The timeout for the step in minutes (default: 60)

.PARAMETER MaxRetryOnFailure
    The number of retries on step failure (default: 0)

.PARAMETER ScriptOutput
    If defined, the output of the script will be stored in this variable and the function will return a boolean indicating the success of the Script
    Otherwise, the output will be returned as a PSCustomObject

.EXAMPLE
    $ScriptOutput = $null
    $ScriptOutput = Invoke-Step -commands 'return 0'

.EXAMPLE
    $ScriptOutput = $null
    Invoke-Step -commands 'return 0' -ScriptOutput ([ref]$ScriptOutput)
#>
[CmdletBinding(DefaultParameterSetName='Default')]
[OutputType([PSCustomObject], [bool])]
param(
    [Parameter(Mandatory)]
    [string[]]$Commands,

    [Parameter(Mandatory=$false)]
    [hashtable]$ScriptInputs = @{},

    [Parameter(Mandatory=$false)]
    [hashtable]$ScriptEnvironment = @{},
    
    [Parameter(Mandatory=$false)]
    [hashtable]$ScriptVariables = @{},

    [Parameter(Mandatory=$false)]
    [string]$DisplayName = 'MetaNull.Invoke-Script',

    [Parameter(Mandatory=$false)]
    [bool]$Enabled = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$Condition = '$true -eq $true',

    [Parameter(Mandatory=$false)]
    [bool]$ContinueOnError = $false,

    [Parameter(Mandatory=$false)]
    [int]$TimeoutInMinutes = 60,

    [Parameter(Mandatory=$false)]
    [int]$MaxRetryOnFailure = 0,
    
    [Parameter(Mandatory, ParameterSetName='Reference')]
    [ref]$ScriptOutput
)
Process {
    # Initialize the step output
    $Return = $null
    '' | Invoke-VisualStudioOnlineString -VsoState ([ref]$Return)

    # Run the step
    $BackupErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Stop"

        # Print all arguments
        if($DebugPreference -eq 'Continue') {
            Write-Debug "Commands: `n> $($Commands -join "`n> ")"
            Write-Debug "ScriptInputs: "
            foreach ($key in $ScriptInputs.Keys) {
                Write-Debug "  $key = $($ScriptInputs[$key])"
            }
            Write-Debug "ScriptEnvironment: "
            foreach ($key in $ScriptEnvironment.Keys) {
                Write-Debug "  $key = $($ScriptEnvironment[$key])"
            }
            Write-Debug "ScriptVariables: "
            foreach ($key in $ScriptVariables.Keys) {
                Write-Debug "  $key = $($ScriptVariables[$key])"
            }
            Write-Debug "Condition: $Condition"
            Write-Debug "ContinueOnError: $ContinueOnError"
            Write-Debug "DisplayName: $DisplayName"
            Write-Debug "Enabled: $Enabled"
            Write-Debug "TimeoutInMinutes: $TimeoutInMinutes"
            Write-Debug "MaxRetryOnFailure: $MaxRetryOnFailure"
        }

        # Initialize the step output
        if($PSCmdlet.ParameterSetName -eq 'Reference') {
            Write-Debug "Returning a boolean, reporting the ScriptOutput by reference"
            $ScriptOutput.Value = $Return
        } else {
            Write-Debug "Returning the ScriptOutput as a value"
            $ScriptOutput = [ref]$Return
        }

        # Set the ScriptVariables
        foreach ($variable in $ScriptVariables.Keys) {
            Write-Debug "Setting variable $variable to $($ScriptVariables[$variable])"
            $ScriptOutput.Value.Variable += ,[pscustomobject]@{
                Name=$variable
                Value=$ScriptVariables[$variable]
                IsSecret=$false
                IsOutput=$false
                IsReadOnly=$false
            }
        }

        # Ensure TimeoutInMinutes is within the valid range, if not set to 5 minutes
        if ($TimeoutInMinutes -le 0 -or $TimeoutInMinutes -ge 1440) {
            $TimeoutInMinutes = 5
        }

        # Check if the step should run (Condition is true)
        $sb_condition = [scriptblock]::Create($Condition)
        if (-not (& $sb_condition)) {
            Write-Debug "Script '$DisplayName' was skipped because the Condition was false."
            $Return.Result.Message = 'Skipped'
            $Return.Result.Result = 'Succeeded'
            if($PSCmdlet.ParameterSetName -eq 'Reference') {
                return $true
            } else {
                return $Return
            }
        }

        # Check if the step should run (step is Enabled)
        if (-not $Enabled) {
            Write-Debug "Script '$DisplayName' was skipped because it was disabled."
            $Return.Result.Message = 'Disabled'
            $Return.Result.Result = 'Succeeded'
            if($PSCmdlet.ParameterSetName -eq 'Reference') {
                return $true
            } else {
                return $Return
            }
        }

        # Set the environment ScriptVariables
        Write-Debug "Adding an environment variable INVOKESECRIPT_CWD to $($PSScriptRoot)"
        [System.Environment]::SetEnvironmentVariable('INVOKESECRIPT_CWD', (Resolve-Path $PSScriptRoot), [System.EnvironmentVariableTarget]::Process)
        foreach ($key in $ScriptEnvironment.Keys) {
            Write-Debug "Setting environment variable $($key.ToUpper() -replace '\W','_') to $($ScriptEnvironment[$key])"
            [System.Environment]::SetEnvironmentVariable(($key.ToUpper() -replace '\W','_'), $ScriptEnvironment[$key], [System.EnvironmentVariableTarget]::Process)
        }
    
        # Create the scriptblocks
        # - Init: set-location
        $sb_init = [scriptblock]::Create("Set-Location $($ScriptInputs.path)")
        # - Step: run the Commands
        $sb_step = [scriptblock]::Create(($Commands | Foreach-Object { 
            # Expand the ScriptVariables
            $Command = $_
            $ScriptOutput.Value.Variable | Foreach-Object {
                $Command = $Command -replace "\$\($($_.Name)\)","$($_.Value)"
            }
            $Command | Write-Output
        }) -join "`n")
        
        # Run the step, optionally retrying on failure
        $Succeeded = $false
        do {
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                Write-Debug "Running script $DisplayName as a Job"
                $job = Start-Job -ScriptBlock $sb_step -ArgumentList @($ScriptInputs.args) -InitializationScript $sb_init 
                while ($job.State -eq 'Running') {
                    Write-Debug "Script '$DisplayName' is running for $($timer.Elapsed.TotalSeconds) seconds"
                    if($timer.Elapsed.TotalMinutes -gt $TimeoutInMinutes) {
                        Write-Debug "Script '$DisplayName' exceeded the timeout of $TimeoutInMinutes minutes and was terminated."
                        $MaxRetryOnFailure = 0
                        Stop-Job -Job $job  | Out-Null
                        $timer.Stop()
                        throw "Script '$DisplayName' exceeded the timeout of $TimeoutInMinutes minutes and was terminated."
                    }
                    Receive-Job -Job $job -Wait:$false | Invoke-VisualStudioOnlineString -VsoState ($ScriptOutput) | Write-Output
                    Start-Sleep -Seconds 1
                }
                Write-Debug "Script '$DisplayName' completed in $($timer.Elapsed.TotalSeconds) seconds"
                Receive-Job -Job $job -Wait | Invoke-VisualStudioOnlineString -VsoState ($ScriptOutput) | Write-Output
                $Succeeded = $true
                break
            } catch {
                # Unforeseen exception => always fail the step
                Write-Warning "Script '$DisplayName' failed because of an unforeseen Exception: $($_.Exception.Message)"
                $ScriptOutput.Value.Result.Result = 'Failed'
                $ScriptOutput.Value.Result.Message = "Exception: $($_)"
                $Succeeded = $false
                # Disable retry on step failure caused by an exception
                $MaxRetryOnFailure = 0
            } finally {
                if($job) {
                    Stop-Job -Job $job | Out-Null
                    Remove-Job -Job $job | Out-Null
                }
            }
        } while(($MaxRetryOnFailure --) -gt 0);

        # Set the scriptresult based on the success of the step, unless if set by the step itself
        if (-not $ScriptOutput.Value.Result) {
            $ScriptOutput.Value.Result.Message = 'Done'
            if($Succeeded) {
                $ScriptOutput.Value.Result.Result = 'Succeeded'
            } elseif ($ContinueOnError) {
                $ScriptOutput.Value.Result.Result = 'SucceededWithIssues'
            } else {
                $ScriptOutput.Value.Result.Result = 'Failed'
            }
        }

        # Return the result
        if($PSCmdlet.ParameterSetName -eq 'Reference') {
            # Return a boolean indicating the success of the step
            return $ScriptOutput.Value.Result.Result -ne 'Failed'
        } else {
            # Return the output as a PSCustomObject
            return $ScriptOutput
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
