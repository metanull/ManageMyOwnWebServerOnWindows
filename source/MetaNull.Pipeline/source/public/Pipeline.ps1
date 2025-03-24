function step_1 {
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

    Begin {

        Function Expand-VsoCommandString {
            <#
    .SYNOPSIS
        Parse a string, checking if it describes a pipeline command (using Azure DevOps' VSO syntax)

    .DESCRIPTION
        Parse a string, checking if it describes a pipeline command (using Azure DevOps' VSO syntax)

    .PARAMETER line
        The string to parse

    .EXAMPLE
        # Parse a string
        '##vso[task.complete result=Succeeded;]Task completed successfully' | Expand-VsoCommandString
#>
[CmdletBinding()]
[OutputType([hashtable])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $line
)
Begin {
    $vso_regex = [regex]::new('^##vso\[(?<command>[\S]+)(?<properties>[^\]]*)\](?<line>.*)$')
}
End {
    
}
Process {
    $vso_return = @{
        Command = $null
        Properties = @{}
        Message = $null
    }

    # Check if the line is null or empty
    if([string]::IsNullOrEmpty($line)) {
        return
    }
    # Check if the line is a VSO command
    $vso = $vso_regex.Match($line)
    if(-not ($vso.Success)) {
        # VSO Command not recognized
        return
    }
    # Parse properties
    $vsoProperties = $vso.Groups['properties'].Value.Trim() -split '\s*;\s*' | Where-Object { -not ([string]::IsNullOrEmpty($_)) } | ForEach-Object {
        $key, $value = $_.Trim() -split '\s*=\s*', 2
        @{"$key" = $value}
    }
    $vsoMessage = $vso.Groups['line'].Value
    switch($vso.Groups['command']) {
        'task.complete' {
            # Requires properties to be in 'result'
            if($vsoProperties.Keys | Where-Object {$_ -notin @('result')}) {
                return
            }
            # Requires property 'result'
            if(-not ($vsoProperties.ContainsKey('result'))) {
                return
            }
            # Requires property 'result' to be 'Succeeded', 'SucceededWithIssues', or 'Failed'
            if (-not ($vsoProperties['result'] -in @('Succeeded', 'SucceededWithIssues', 'Failed'))) {
                return
            }
            $vso_return.Command = 'task.complete'
            $vso_return.Message = $vsoMessage
            switch($vsoProperties['result']) {
                'Succeeded' {               $vso_return.Properties = @{Result = 'Succeeded'}}
                'SucceededWithIssues' {     $vso_return.Properties = @{Result = 'SucceededWithIssues'}}
                'Failed' {                  $vso_return.Properties = @{Result = 'Failed'}}
                default {                   
                    return 
                }
            }
            return $vso_return
        }
        'task.setvariable' {
            # Requires properties to be in 'variable', 'isSecret', 'isOutput', and 'isReadOnly'
            if($vsoProperties.Keys | Where-Object {$_ -notin @('variable','isSecret','isOutput','isReadOnly')}) {
                return
            }
            # Requires property 'variable'
            if(-not ($vsoProperties.ContainsKey('variable'))) {
                return
            }
            # Requires property 'variable' to be not empty
            if([string]::IsNullOrEmpty($vsoProperties['variable'])) {
                return
            }
            # Requires property 'variable' to be a valid variable name
            try {&{Invoke-Expression "`$$($vsoProperties['variable']) = `$null"} } catch {
                return
            }
            $vso_return.Command = 'task.setvariable'
            $vso_return.Message = $null
            $vso_return.Properties = @{
                Name = $vsoProperties['variable']
                Value = $vsoMessage
                IsSecret = $vsoProperties.ContainsKey('isSecret')
                IsOutput = $vsoProperties.ContainsKey('isOutput')
                IsReadOnly = $vsoProperties.ContainsKey('isReadOnly')
            }
            return $vso_return
        }
        'task.setsecret' {
            # Requires no properties
            if($vsoProperties.Keys.Count -ne 0) {
                return
            }
            # Requires message
            if(([string]::IsNullOrEmpty($vsoMessage))) {
                return
            }
            $vso_return.Command = 'task.setsecret'
            $vso_return.Message = $null
            $vso_return.Properties = @{
                Value = $vsoMessage
            }
            return $vso_return
        }
        'task.prependpath' {
            # Requires no properties
            if($vsoProperties.Keys.Count -ne 0) {
                return
            }
            # Requires message
            if(([string]::IsNullOrEmpty($vsoMessage))) {
                return
            }
            $vso_return.Command = 'task.prependpath'
            $vso_return.Message = $null
            $vso_return.Properties = @{
                Value = $vsoMessage
            }
            return $vso_return
        }
        'task.uploadfile' {
            # Requires no properties
            if($vsoProperties.Keys.Count -ne 0) {
                return
            }
            # Requires message
            if(([string]::IsNullOrEmpty($vsoMessage))) {
                return
            }
            $vso_return.Command = 'task.uploadfile'
            $vso_return.Message = $null
            $vso_return.Properties = @{
                Value = $vsoMessage
            }
            return $vso_return
        }
        'task.setprogress' {
            # Requires properties to be in 'value'
            if($vsoProperties.Keys | Where-Object {$_ -notin @('value')}) {
                return
            }
            # Requires property 'value'
            if(-not ($vsoProperties.ContainsKey('value'))) {
                return
            }
            # Requires property 'value' to be an integer
            $tryparse = $null
            if(-not ([int]::TryParse($vsoProperties['value'], [ref]$tryparse))) {
                return
            }
            $vso_return.Command = 'task.setprogress'
            $vso_return.Message = $vsoMessage
            $vso_return.Properties = @{Value = "$tryparse"}
            return $vso_return
        }
    }

    # VSO Command not recognized
    return
}

        }
        Function Expand-VsoFormatString {
            <#
    .SYNOPSIS
        Parse a string, checking if it contains fomratting instructions (using Azure DevOps' VSO syntax)

    .DESCRIPTION
        Parse a string, checking if it contains fomratting instructions (using Azure DevOps' VSO syntax)

    .PARAMETER line
        The string to parse

    .EXAMPLE
        # Parse a string
        '##[section]Start of the section' | Expand-VsoFormatString
#>
[CmdletBinding()]
[OutputType([object])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $line
)
Begin {
    $vso_regex = [regex]::new('^##\[(?<format>group|endgroup|section|warning|error|debug|command)\](?<line>.*)$')
}
End {
    
}
Process {
    # Check if the line is null or empty
    if([string]::IsNullOrEmpty($line)) {
        return
    }
    # Check if the line is a VSO command
    $vso = $vso_regex.Match($line)
    if(-not ($vso.Success)) {
        # VSO Command not recognized
        return $line
    }
    return @{
        Format = $vso.Groups['format'].Value
        Message = $vso.Groups['line'].Value
    }
}

        }
        Function Invoke-VsoCommand {
            param(
                [Parameter(Mandatory,ValueFromPipeline)]
                [hashtable]$vso,
                [Parameter(Mandatory)]
                [ref]$StepOutput
            )
            Process {
                switch($vso.Command) {
                    'task.complete' {
                        $taskResult = [PSCustomObject]$vso.Properties
                        $taskResult | Add-Member -MemberType NoteProperty -Name 'Message' -Value ($vso.Message)
                        $StepOutput.Value.Result += ,$taskResult
                        return
                    }
                    'task.setvariable' {
                        $taskVariable = [PSCustomObject]$vso.Properties
                        $StepOutput.Value.Variable += ,$taskVariable
                        return
                    }
                    'task.setsecret' {
                        $StepOutput.Value.Secret += ,$vso.Properties.Value
                        return
                    }
                    'task.prependpath' {
                        $StepOutput.Value.Path += ,$vso.Properties.Value
                        return
                    }
                    default {
                        Write-Warning "Unknown VSO Command: $($vso.Command)"
                    }
                }
            }
        }
        Function Out-Vso {
            param(
                [Parameter(Mandatory,ValueFromPipeline)]
                [object]$OutputObject,

                [Parameter(Mandatory)]
                [ref]$StepOutput
            )
            Process {
                $VsoCommand = $OutputObject | Expand-VsoCommandString
                if($VsoCommand) {
                    $VsoCommand | Invoke-VsoCommand -StepOutput ($StepOutput)
                    return
                }
                $StepOutput.Value.Secret | Foreach-Object {
                    $OutputObject = $OutputObject -replace $_, '***'
                }
                $VsoOutput = $OutputObject | Expand-VsoFormatString
                if($VsoOutput -is [hashtable] -and $VsoOutput.ContainsKey('Format') -and $VsoOutput.ContainsKey('Message')) {
                    switch($VsoOutput.Format) {
                        'group' {
                            Write-Host "[+] $($VsoOutput.Message)" -ForegroundColor Magenta
                            return
                        }
                        'endgroup' {
                            Write-Host "[-] $($VsoOutput.Message)" -ForegroundColor Magenta
                            return
                        }
                        'section' {
                            Write-Host "$($VsoOutput.Message)" -ForegroundColor Cyan
                            return
                        }
                        'warning' {
                            Write-Host "WARNING: $($VsoOutput.Message)" -ForegroundColor Yellow
                            return
                        }
                        'error' {
                            Write-Host "ERROR: $($VsoOutput.Message)" -ForegroundColor Red
                            return
                        }
                        'debug' {
                            Write-Host "DEBUG: $($VsoOutput.Message)" -ForegroundColor Gray
                            return
                        }
                        'command' {
                            Write-Host "$($VsoOutput.Message)" -ForegroundColor Blue
                            return
                        }
                    }
                }
                $VsoOutput | Write-Output
            }
        }
    }
    Process {
        $StepOutput.Value = [PSCustomObject]@{
            Variable = @(,[pscustomobject]@{Name='SAMPLE_VARIABLE';Value=127;IsSecret=$false;IsOutput=$false;IsReadOnly=$false})
            Result = @()
            Secret = @()
            Path = @()
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

        # Run the step
        $BackupErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Stop"
            
            # Create the scriptblocks
            $sb_init = [scriptblock]::Create("Set-Location $($stepInput.path)")
            #$sb_init = [scriptblock]::Create("Set-Location $($env:STEP_CWD)")
            $sb_step = [scriptblock]::Create(($commands |% { 
                $Command = $_
                $StepOutput.Value.Variable |% {
                    $Command = $Command -replace "\$\($($_.Name)\)","$($_.Value)"
                }
                $Command | Write-Output
            }) -join "`n")
            
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

            #return $jobResult
        } finally {
            $ErrorActionPreference = $BackupErrorActionPreference
        }
    }
}

$StepOutput = $null
$StepParams = @{
    StepOutput = [ref]$StepOutput
    stepInput = @{something = @(); path = (Resolve-Path 'E:\ManageMyOwnWebServerOnWindows')}
    condition = '$true -eq $true'
    continueOnError = $false
    displayName = 'Step 1'
    enabled = $true
    env = @{WHOAMI = $env:USERNAME; CWD = (Resolve-Path .)}
    timeoutInMinutes = 1
    retryCountOnStepFailure = 2
    commands = @(
            '$d = get-date'
            '"##vso[task.setsecret]HelloWorld42!" | Write-Output'
            '"##[section]Hello $($env:WHOAMI), it is $($d), working in $($env:STEP_CWD), My Password: HelloWorld42!" | write-output'
            '"##[warning]SAMPLE_VARIABLE $(SAMPLE_VARIABLE)" | Write-Output'
            '$g = get-command git'
            '"##[command]git $($args -join '' '')" | write-output'
            'Start-Sleep -Seconds 3'
            #'try {'
            '&($g) status 2>&1 | Tee-Object -Variable git_out | Out-Null'
            '"##vso[task.setvariable variable=GIT_RESULT]$LASTEXITCODE" | Write-Output'
            #'} catch{}'
            'if($LASTEXITCODE -ne 0) {'
                '"##[error]#$LASTEXITCODE. $git_out" | write-output'
                'throw "Git failed: #$LASTEXITCODE. $git_out"'
            '} else {'
                '"##[group]Command output:" | write-Output'
                '$git_out|%{"$_" | write-output}'
                '"##[endgroup]" | write-Output'
            '}'
            '"##vso[task.complete result=succeeded]Done" | Write-Output'
            
        )
}

step_1 @StepParams -Verbose

$StepOutput | Format-List
# step_1