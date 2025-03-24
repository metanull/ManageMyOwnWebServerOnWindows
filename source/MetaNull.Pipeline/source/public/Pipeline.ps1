function task_1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$taskInput = @{args = @();path = '.'},
        [Parameter(Mandatory=$false)]
        [string]$condition = '$true -eq $true',
        [Parameter(Mandatory=$false)]
        [bool]$continueOnError = $false,
        [Parameter(Mandatory=$false)]
        [string]$displayName = 'Task 1',
        [Parameter(Mandatory=$false)]
        [bool]$enabled = $true,
        [Parameter(Mandatory=$false)]
        [hashtable]$env = @{WHOAMI = $env:USERNAME},
        [Parameter(Mandatory=$false)]
        [int]$timeoutInMinutes = 60,
        [Parameter(Mandatory=$false)]
        [int]$retryCountOnTaskFailure = 0,
        [Parameter(Mandatory=$false)]
        [string[]]$commands = @(
            'return 0'
        ),

        [Parameter(Mandatory)]
        [ref]$InOutVariable,
        [Parameter(Mandatory)]
        [ref]$InOutPath,
        [Parameter(Mandatory)]
        [ref]$InOutSecret,
        [Parameter(Mandatory)]
        [ref]$OutResult
    )

    # Ensure timeoutInMinutes is within the valid range, if not set to 5 minutes
    if ($timeoutInMinutes -le 0 -or $timeoutInMinutes -ge 1440) {
        $timeoutInMinutes = 5
    }

    # Check if the task should run (condition is true and task is enabled)
    $sb_condition = [scriptblock]::Create($condition)
    if (-not (& $sb_condition)) {
        Write-Warning "Task '$displayName' was skipped because the condition was false."
        return
    }
    if (-not $enabled) {
        Write-Warning "Task '$displayName' was skipped because it was disabled."
        return
    }

    # Set the environment variables
    [System.Environment]::SetEnvironmentVariable('TASK_CWD', (Resolve-Path $PSScriptRoot), [System.EnvironmentVariableTarget]::Process)
    foreach ($key in $env.Keys) {
        [System.Environment]::SetEnvironmentVariable(($key.ToUpper() -replace '\W','_'), $env[$key], [System.EnvironmentVariableTarget]::Process)
    }
    
    # Print all arguments
        Write-Verbose "taskInput: "
        foreach ($key in $taskInput.Keys) {
            Write-Verbose "  $key = $($taskInput[$key])"
        }
        Write-Verbose "condition: $condition"
        Write-Verbose "continueOnError: $continueOnError"
        Write-Verbose "displayName: $displayName"
        Write-Verbose "enabled: $enabled"
        Write-Verbose "env: "
        foreach ($key in $env.Keys) {
            Write-Verbose "  $key = $($env[$key])"
        }
        Write-Verbose "TASK_ENV: "
        Get-ChildItem env: | where-object { $_.name -like 'TASK_*' } | foreach-object {
            Write-Verbose "  $($_.Name) = $($_.Value)"
        }
        Write-Verbose "timeoutInMinutes: $timeoutInMinutes"
        Write-Verbose "retryCountOnTaskFailure: $retryCountOnTaskFailure"
        Write-Verbose "commands: `n> $($commands -join "`n> ")"	

    # Run the task
    $BackupErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Stop"
        
        $sb_init = [scriptblock]::Create("Set-Location $($taskInput.path)")
        #$sb_init = [scriptblock]::Create("Set-Location $($env:TASK_CWD)")
        $sb_task = [scriptblock]::Create($commands -join "`n")
        
        do {
            $retryCountOnTaskFailure --
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $job = Start-Job -ScriptBlock $sb_task -ArgumentList @($taskInput.args) -InitializationScript $sb_init 
                while ($job.State -eq 'Running') {
                    if($timer.Elapsed.TotalMinutes -gt $timeoutInMinutes) {
                        $retryCountOnTaskFailure = 0
                        Stop-Job -Job $job  | Out-Null
                        $timer.Stop()
                        throw "Task exceeded the timeout of $timeoutInMinutes minutes and was terminated."
                    }
                    Receive-Job -Job $job -Wait:$false
                    Start-Sleep -Seconds 1
                }
                Receive-Job -Job $job
                break
            } catch {
                Write-Warning "Task '$displayName' failed because of an Exception: $_.Exception.Message"
            } finally {
                if($job) {
                    Remove-Job -Job $job | Out-Null
                }
            }
        } while($retryCountOnTaskFailure -gt 0);

        #return $jobResult
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}

$InOutVariable = $null
$InOutPath = $null
$InOutSecret = $null
$OutResult = $null
$TaskParams = @{
    InOutVariable = [ref]$InOutVariable
    InOutPath= [ref]$InOutPath
    InOutSecret = [ref]$InOutSecret
    OutResult= [ref]$OutResult
    taskInput = @{something = @(); path = (Resolve-Path 'E:\ManageMyOwnWebServerOnWindows')}
    condition = '$true -eq $true'
    continueOnError = $false
    displayName = 'Task 1'
    enabled = $true
    env = @{WHOAMI = $env:USERNAME; CWD = (Resolve-Path .)}
    timeoutInMinutes = 1
    retryCountOnTaskFailure = 0
    commands = @(
            '$d = get-date'
            '"##[section]Hello $($env:WHOAMI), it is $($d), working in $($env:TASK_CWD)" | write-output'
            '$g = get-command git'
            '"##[command]git $($args -join '' '')" | write-output'
            'Start-Sleep -Seconds 3'
            #'try {'
            '&($g) status 2>&1 | Tee-Object -Variable git_out | Out-Null'
            #'} catch{}'
            'if($LASTEXITCODE -ne 0) {'
                '"##[error]#$LASTEXITCODE. $git_out" | write-output'
                'throw "Git failed: #$LASTEXITCODE. $git_out"'
            '} else {'
                '"##[group]Command output:" | write-Output'
                '$git_out|%{"$_" | write-output}'
                '"##[endgroup]" | write-Output'
            '}'
        )
}

task_1 @TaskParams -Verbose
# task_1