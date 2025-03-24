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
        [int]$timeoutInMinutes = 5,
        [Parameter(Mandatory=$false)]
        [int]$retryCountOnTaskFailure = 0,
        [Parameter(Mandatory=$false)]
        [string[]]$commands = @(
            'return 0'
        )
    )

    $sb_condition = [scriptblock]::Create($condition)
    if (-not (& $sb_condition)) {
        return 0
    }
    if (-not $enabled) {
        return 0
    }
    foreach ($key in $env.Keys) {
        [System.Environment]::SetEnvironmentVariable(($key.ToUpper() -replace '\W','_'), $env[$key], [System.EnvironmentVariableTarget]::Process)
    }
    [System.Environment]::SetEnvironmentVariable('TASK_CWD', (Resolve-Path $PSScriptRoot), [System.EnvironmentVariableTarget]::Process)
    
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
    gci env: | where-object { $_.name -like 'TASK_*' } | foreach-object {
        Write-Verbose "  $($_.Name) = $($_.Value)"
    }
    Write-Verbose "timeoutInMinutes: $timeoutInMinutes"
    Write-Verbose "retryCountOnTaskFailure: $retryCountOnTaskFailure"
    Write-Verbose "commands: `n> $($commands -join "`n> ")"	

    try {
        $BackupErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        if($continueOnError -eq $true) {
            $ErrorActionPreference = "Continue"
        }
        $sb_init = [scriptblock]::Create("Set-Location $($taskInput.path)")
        #$sb_init = [scriptblock]::Create("Set-Location $($env:TASK_CWD)")
        
        $sb_task = [scriptblock]::Create($commands -join "`n")

        try {
            Write-Warning "Task 1 - $displayName - $($taskInput.path)"
            $job = Start-Job -ScriptBlock $sb_task -ArgumentList @($taskInput.args) -InitializationScript $sb_init 
            if ($timeoutInMinutes -gt 0) {
                $job | Wait-Job -Timeout ($timeoutInMinutes * 60) | Out-Null
                if ($job.State -eq 'Running') {
                    Stop-Job -Job $job  | Out-Null
                    throw "Task exceeded the timeout of $timeoutInMinutes minutes and was terminated."
                }
            }
            $jobResult = Receive-Job -Job $job
        } catch {
            if ($retryCountOnTaskFailure -gt 0) {
                Write-Warning "Task 1 - $displayName failed. Retrying..."
                Write-Warning $_
                Start-Sleep -Seconds 5
                $taskParams = @{
                    taskInput = $taskInput
                    condition = $condition
                    continueOnError = $continueOnError
                    displayName = $displayName
                    enabled = $enabled
                    env = $env
                    timeoutInMinutes = $timeoutInMinutes
                    retryCountOnTaskFailure = ($retryCountOnTaskFailure - 1)
                    commands = $commands
                }
                return task_1 @taskParams
            }
            
            # TO DO TO DO TO DO
            # TO DO TO DO TO DO
            # Should not throw, but log a FAILURE instead
            Write-Warning "TO DO: SHOULD NOT THROW HERE"
            throw $_
            # TO DO TO DO TO DO
            # TO DO TO DO TO DO

        } finally {
            if($job) {
                Remove-Job -Job $job | Out-Null
            }
        }
        $jobResult | Foreach-Object {

            # if ($_ -is [System.Management.Automation.ErrorRecord]) {
            #    Write-Error $_
            #}

            $vso_regex = [regex]::new('^##vso\[(?<command>[\S]+)(?<properties>[^\]]*)\](?<line>.*)$')
            $format_regex = [regex]::new('^##\[(?<format>group|endgroup|section|command|warning|error)\](?<line>.*)$')

            $vso = $vso_regex.Match($_)
            $format = $format_regex.Match($_)
            if($vso.Success) {
                #$vso.Groups['command']
                #$vso.Groups['properties']
                #$vso.Groups['line']
                switch($vso.Groups['command']) {
                    #'task.complete' {
                    #    $CompleteStatus=$vso.Groups['properties']
                    #}
                    #'task.setvariable' {
                    #    $SetVarName=$vso.Groups['properties']
                    #    $SetVarValue=$vso.Groups['line']
                    #    [System.Environment]::SetEnvironmentVariable($SetVarName, $SetVarValue, [System.EnvironmentVariableTarget]::Process)
                    #}
                    default {
                        Write-Host $_
                    }
                }
            } elseif( $format.Success ) {
                switch($format.Groups['format']) {
                    'group' {
                        Write-Host "[+] $($format.Groups['line'])" -ForegroundColor Magenta
                    }
                    'endgroup' {
                        Write-Host "[-] $($format.Groups['line'])" -ForegroundColor Magenta
                    }
                    'section' {
                        Write-Host "$($format.Groups['line'])" -ForegroundColor Cyan
                    }
                    'command' {
                        Write-Host "$($format.Groups['line'])" -ForegroundColor Yellow
                    }
                    'warning' {
                        Write-Warning "WARNING: $($format.Groups['line'])"
                    }
                    'error' {
                        Write-Error "ERROR: $($format.Groups['line'])"
                    }
                    default {
                        Write-Host $_
                    }
                }
                
            } else {
                Write-Host $_
            }
        }
        #return $jobResult
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}

$TaskParams = @{
    taskInput = @{args = @('status');path = (Resolve-Path 'E:\ManageMyOwnWebServerOnWindows')}
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
            #'try {'
            '&($g) @args 2>&1 | Tee-Object -Variable git_out | Out-Null'
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