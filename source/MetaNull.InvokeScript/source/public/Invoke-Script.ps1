<#
.SYNOPSIS
    Invoke a script, defined as an array of strings

.DESCRIPTION
    Invoke a script, defined as an array of strings
    (Purpose: Run a step from a pipeline)

.PARAMETER Commands
    The Commands to run in the step
    @("'Hello World' | Write-Output"), for example

.PARAMETER ScriptInput
    The input to the script (optional arguments received from the pipeline definition) (default: @{})
    @{args = @(); path = '.'}, for example

.PARAMETER ScriptEnvironment
    The environment ScriptVariable to set for the step (default: @{})
    They are added to the script's local environment
    @{WHOAMI = $env:USERNAME}, for example

.PARAMETER ScriptVariable
    The ScriptVariable to set for the step (default: @{})
    They are used to expand variables in the Commands. Format of the variable is $(VariableName)
    @{WHOAMI = 'Pascal Havelange'}, for example

.PARAMETER DisplayName
    The display name of the step (default: 'MetaNull.Invoke-Script')

.PARAMETER Enabled
    Is the step Enabled (default: $true)

.PARAMETER Condition
    The Condition to run the step (default: '$true')

.PARAMETER ContinueOnError
    Continue on error (default: $false)
    If set to true, in case of error, the result will indicate that the step has 'completed with issues' instead of 'failed'

.PARAMETER TimeoutInSeconds
    The timeout in seconds after which commands will be aborted (range: 1 to 86400 (1 day); default: 300 (15 minutes))

.PARAMETER MaxRetryOnFailure
    The number of retries on step failure (default: 0)

.PARAMETER ScriptOutput
    The output of the script will be stored in this variable and the function returns the commands' output

.EXAMPLE
    $ScriptOutput = $null
    $ScriptOutput = Invoke-Script -commands '"Hello World"|Write-Output'

.EXAMPLE
    $ScriptOutput = $null
    Invoke-Script -commands '"Hello World"|Write-Output' -ScriptOutput ([ref]$ScriptOutput)
#>
[CmdletBinding(DefaultParameterSetName='Default')]
[OutputType([PSCustomObject], [bool])]
param(
    [Parameter(Mandatory)]
    [string[]]$Commands,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_})]
    [string]$ScriptWorkingDirectory = '.',

    [Parameter(Mandatory=$false)]
    [hashtable]$ScriptInput = @{},

    [Parameter(Mandatory=$false)]
    [hashtable]$ScriptEnvironment = @{},
    
    [Parameter(Mandatory=$false)]
    [hashtable]$ScriptVariable = @{},

    [Parameter(Mandatory=$false)]
    [string]$DisplayName = 'MetaNull.Invoke-Script',

    [Parameter(Mandatory=$false)]
    [switch]$Enabled,
    
    [Parameter(Mandatory=$false)]
    [string]$Condition = '$true',

    [Parameter(Mandatory=$false)]
    [switch]$ContinueOnError,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1,86400)]
    [int]$TimeoutInSeconds = 300,

    [Parameter(Mandatory=$false)]
    [int]$MaxRetryOnFailure = 0,
    
    [Parameter(Mandatory)]
    [ref]$ScriptOutput
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Stop"

        # Create an empty Result object
        '' | Invoke-VisualStudioOnlineString -ScriptOutput $ScriptOutput

        <# 
         # Create an empty Result object
         $ReturnObject_value = $null
         '' | Invoke-VisualStudioOnlineString -ScriptOutput ([ref]$ReturnObject_value)
        
         Assign the result object, to permit reporting by reference and/or returning the object
         if($PSCmdlet.ParameterSetName -eq 'Reference') {
            # Function will return a boolean, reporting is done through $ScriptOutput by reference"
            $ScriptOutput.Value = $ReturnObject_value
         } else {
            # Function will return the $ScriptOutput object
            $ScriptOutput = [ref]$ReturnObject_value
         }
        #>

        # Check if the step should run (step is Enabled)
        if ($Enabled.IsPresent -and -not $Enabled) {
            Write-Debug "Script '$DisplayName' was skipped because it was disabled."
            Set-Result -ScriptOutput $ScriptOutput -Message 'Disabled'
            throw $true # Interrupts the flow, $true is interpreted as a success
        }

        # Add received input variables to the ScriptOutput
        foreach ($key in $ScriptVariable.Keys) {
            Add-Variable -ScriptOutput $ScriptOutput -Name $key -Value $ScriptVariable[$key]
        }

        # Add received input environment variables to the process' environment
        Add-Environment -ScriptOutput $ScriptOutput -Name 'METANULL_CURRENT_DIRECTORY' -Value ([System.Environment]::CurrentDirectory)
        Add-Environment -ScriptOutput $ScriptOutput -Name 'METANULL_CURRENT_LOCATION' -Value ((Get-Location).Path)
        Add-Environment -ScriptOutput $ScriptOutput -Name 'METANULL_SCRIPT_ROOT' -Value (Resolve-Path $PSScriptRoot)
        Add-Environment -ScriptOutput $ScriptOutput -Name 'METANULL_WORKING_DIRECTORY' -Value (Resolve-Path $ScriptWorkingDirectory)
        foreach ($key in $ScriptEnvironment.Keys) {
            Add-Environment -ScriptOutput $ScriptOutput -Name $key -Value $ScriptEnvironment[$key]
        }

        # Check if the step should run (Condition is true)
        $sb_condition = [scriptblock]::Create(($Condition | Expand-Variables -ScriptOutput $ScriptOutput))
        if (-not (& $sb_condition)) {
            Write-Debug "Script '$DisplayName' was skipped because the Condition was false."
            Set-Result -ScriptOutput $ScriptOutput -Message 'Skipped'
            throw $true # Interrupts the flow, $true is interpreted as a success
        }
    
        # Create the scriptblocks
        # - Init: set-location
        $sb_init = [scriptblock]::Create(
            @(
                '$ErrorActionPreference = "Stop"'
                '$DebugPreference = "SilentlyContinue"'
                '$VerbosePreference = "SilentlyContinue"'
                "Set-Location $($ScriptWorkingDirectory)"
            ) -join "`n"
        )
        # - Step: run the Commands
        $sb_step = [scriptblock]::Create(($Commands | Expand-Variables -ScriptOutput $ScriptOutput) -join "`n")

        # Set a timer, after which the job will be interrupted, if not yet complete
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Run the step, optionally retrying on failure
        do {
            Write-Debug "Running script $DisplayName as a Job"
            $job = Start-Job -ScriptBlock $sb_step -ArgumentList @($ScriptInput.args) -InitializationScript $sb_init 
            try {
                # Wait for job to complete
                while ($job.State -eq 'Running') {
                    Start-Sleep -Milliseconds 250
                    # Collect and process job's (partial) output
                    try {
                        $Partial = Receive-Job -Job $job -Wait:$false
                        $Partial | Invoke-VisualStudioOnlineString -ScriptOutput $ScriptOutput | Write-Output
                    } catch {
                        Add-Error -ScriptOutput $ScriptOutput -ErrorRecord $_
                    }
                    # Interrupt the job if it takes too long
                    if($timer.Elapsed.TotalSeconds -gt $TimeoutInSeconds) {
                        Set-Result -ScriptOutput $ScriptOutput -Failed -Message 'Job timed out.'
                        Stop-Job -Job $job | Out-Null
                    }
                }
                # Collect and process job's (remaining) output
                if($job.HasMoreData) {
                    try {
                        $Partial = Receive-Job -Job $job -Wait
                        $Partial | Invoke-VisualStudioOnlineString -ScriptOutput $ScriptOutput | Write-Output
                    } catch {
                        Add-Error -ScriptOutput $ScriptOutput -ErrorRecord $_
                    }
                }

                # Process job result
                if($job.State -eq 'Completed') {
                    # Interrupt the retry loop, the job si complete
                    Set-Result -ScriptOutput $ScriptOutput -Message $job.State
                    break       
                } elseif($job.State -eq 'Failed' -and $MaxRetryOnFailure -gt 0) {
                    # Keep on with the retry loop, as the job has failed, and we didn't reach yet the maximum number of allowed retries
                    Write-Debug "Job failed, retrying up to $MaxRetryOnFailure time(s)"
                    $ScriptOutput.Value.Retried ++
                    continue    
                } else {
                    # Interrupt the retry loop: Unexpected job.state and/or out of allowed retries => we shouldn't permit retrying
                    if($ContinueOnError.IsPresent -and $ContinueOnError) {
                        Set-Result -ScriptOutput $ScriptOutput -SucceededWithIssues -Message $job.State
                    } else {
                        Set-Result -ScriptOutput $ScriptOutput -Failed -Message $job.State
                    }
                    break
                }
            } finally {
                Write-Debug "Script '$DisplayName' ran for $($timer.Elapsed.TotalSeconds) seconds. Final job's state: $($job.State)"
                Remove-Job -Job $job -Force | Out-Null
            }
        } while(($MaxRetryOnFailure --) -gt 0)

    } catch {
        if($_.TargetObject -is [bool] -and $_.TargetObject -eq $true) {
            # This is a voluntary interruption of the flow... Do nothing
        } else {
            # This is an actual exception... Handle it
            Add-Error -ScriptOutput $ScriptOutput -ErrorRecord $_
            if($ContinueOnError.IsPresent -and $ContinueOnError) {
                Set-Result -ScriptOutput $ScriptOutput -SucceededWithIssues -Message $_
            } else {
                Set-Result -ScriptOutput $ScriptOutput -Failed -Message $_
            }
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }

    <#
    # Return the Result Object, or a boolean
    if($PSCmdlet.ParameterSetName -eq 'Reference') {
        # Return a boolean, the reporting was done through the [ref]$ScriptOutput parameter
        return (Test-Result -ScriptOutput $ScriptOutput)
    } else {
        # Return the result object
        return $ReturnObject_value
    }
    #>
}
Begin {
    <#
        .SYNOPSIS
            Update the ScriptOutput object to indicate the Success or Failure of the operation
    #>
    Function Set-Result {
        [CmdletBinding(DefaultParameterSetName='Succeeded')]
        param(
            [Parameter(Mandatory)]
            [ref]$ScriptOutput,
            [Parameter(Mandatory = $false)]
            [string]$Message = 'Done',
            [Parameter(Mandatory,ParameterSetName='Failed')]
            [switch]$Failed,
            [Parameter(Mandatory,ParameterSetName='SucceededWithIssues')]
            [switch]$SucceededWithIssues
        )
        Process {
            $Result = [pscustomobject]@{
                Message = $Message
                Result = 'Succeeded'
            }
            if($Failed.IsPresent -and $Failed) {
                $Result.Result = 'Failed'
            }
            if($SucceededWithIssues.IsPresent -and $SucceededWithIssues) {
                $Result.Result = 'SucceededWithIssues'
            }
            $ScriptOutput.Value.Result = $Result
        }
    }
    <#
        .SYNOPSIS
            Check the Success of Failure status from the ScriptOutput object, return $true in case of Success, or $false  otherwise.
    #>
    Function Test-Result {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ref]$ScriptOutput
        )
        Process {
            switch ($ScriptOutput.Value.Result.Result) {
                'Succeeded' {           return $true    }
                'SucceededWithIssues' { return $true    }
                'Failed' {              return $false   }
            }
            return $false
        }
    }
    <#
        .SYNOPSIS
            Add to the process' environment variables
    #>
    Function Add-Environment {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ref]$ScriptOutput,

            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string]$Value
        )
        Process {
            Write-Debug "Adding to process' environment: $($Name.ToUpper() -replace '\W','_') = $($Value)"
            [System.Environment]::SetEnvironmentVariable(($Name.ToUpper() -replace '\W','_'), $Value, [System.EnvironmentVariableTarget]::Process)
        }
    }
    <#
        .SYNOPSIS
            Update the ScriptOutput object, adding some user defined variables (variables are later expanded when generating the Script's content)
    #>
    Function Add-Variable {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ref]$ScriptOutput,

            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string]$Value
        )
        Process {
            Write-Debug "Adding to process' variables: $($Name) = $($Value)"
            $ScriptOutput.Value.Variable += ,[pscustomobject]@{
                Name=$Name
                Value=[System.Environment]::ExpandEnvironmentVariables($Value)
                IsSecret=$false
                IsOutput=$false
                IsReadOnly=$false
            }
        }
    }
    <#
        .SYNOPSIS
            Update the ScriptOutput object, adding some ErrorRecord to the Error array
    #>
    Function Add-Error {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ref]$ScriptOutput,

            [Parameter(Mandatory)]
            [object]$ErrorRecord
        )
        Process {
            Write-Debug "Adding an error to the result: $($ErrorRecord.ToString())"
            $ScriptOutput.Value.Error += ,$ErrorRecord
        }
    }
    <#
        .SYNOPSIS
            Detect and expand user defined variables in a string
    #>
    Function Expand-Variables {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ref]$ScriptOutput,

            [Parameter(Mandatory,ValueFromPipeline)]
            [string]$String
        )
        Process {
            $ExpandedString = $_
            # Expand the Variables found in the command
            $ScriptOutput.Value.Variable | Foreach-Object {
                $ExpandedString = $ExpandedString -replace "\$\($($_.Name)\)","$($_.Value)"
            }
            # [System.Environment]::ExpandEnvironmentVariables($ExpandedString) | Write-Output
            $ExpandedString | Write-Output
        }
    }
}