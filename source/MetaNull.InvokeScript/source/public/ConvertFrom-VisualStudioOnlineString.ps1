[CmdletBinding(DefaultParameterSetName='Default')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored pipeline output')]
[OutputType([hashtable])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $String
)
Begin {
    $VisualStudioOnlineExpressions = @(
        @{
            Name = 'Command'
            Expression = '^##vso\[(?<command>[\S]+)(?<properties>[^\]]*)\](?<line>.*)$'
        }
        @{
            Name = 'Format'
            Expression = '^##\[(?<format>group|endgroup|section|warning|error|debug|command)\](?<line>.*)$'
        }
    )
}
Process {
    # Check if the line is null or empty
    if ([string]::IsNullOrEmpty($String)) {
        return
    }
    
    # Evaluate each regular expression against the received String
    foreach($Expression in $VisualStudioOnlineExpressions) {
        $RxExpression = [regex]::new($Expression.Expression)
        $RxResult = $RxExpression.Match($String)
        if ($RxResult.Success) {
            $Vso = @{
                Type = $Expression.Name
                Expression = $Expression.Expression
                Matches = $RxResult
            }
            break
        }
    }
    if(-not $Vso.Type) {
        return
    }
    
    # Handle known commands, or return
    if($Vso.Type -eq 'Format') {
        return @{
            Format = $Vso.Matches.Groups['format'].value
            Message = $Vso.Matches.Groups['line'].value
        }
    } 
    if($Vso.Type -eq 'Command') {
        # "> Command: $String" | Write-Debug
        $Properties = @{}
        $Vso.Matches.Groups['properties'].Value.Trim() -split '\s*;\s*' | Where-Object { 
            -not ([string]::IsNullOrEmpty($_)) 
        } | ForEach-Object {
            $key, $value = $_.Trim() -split '\s*=\s*', 2
            # "{$key = $value}" | Write-Debug
            $Properties += @{"$key" = $value }
        }
        switch ($Vso.Matches.Groups['command']) {
            'task.complete' {
                # Requires properties to be in 'result'
                if ($Properties.Keys | Where-Object { $_ -notin @('result') }) {
                    return
                }
                # Requires property 'result'
                if (-not ($Properties.ContainsKey('result'))) {
                    return
                }
                # Requires property 'result' to be 'Succeeded', 'SucceededWithIssues', or 'Failed'
                if (-not ($Properties['result'] -in @('Succeeded', 'SucceededWithIssues', 'Failed'))) {
                    return
                }
                # Return the command
                switch ($Properties['result']) {
                    'Succeeded' { $Result = 'Succeeded' }
                    'SucceededWithIssues' { $Result = 'SucceededWithIssues' }
                    'Failed' { $Result = 'Failed' }
                    default {                   
                        return 
                    }
                }
                return @{
                    Command = 'task.complete'
                    Message = $Vso.Matches.Groups['line'].Value
                    Properties = @{ 
                        Result = $Result
                    }
                }
            }
            'task.setvariable' {
                # Requires properties to be in 'variable', 'isSecret', 'isOutput', and 'isReadOnly'
                if ($Properties.Keys | Where-Object { $_ -notin @('variable', 'isSecret', 'isOutput', 'isReadOnly') }) {
                    Write-Warning "Invalid properties"
                    return
                }
                # Requires property 'variable'
                if (-not ($Properties.ContainsKey('variable'))) {
                    Write-Warning "Missing name"
                    return
                }
                # Requires property 'variable' to be not empty
                if ([string]::IsNullOrEmpty($Properties['variable'])) {
                    Write-Warning "Null name"
                    return
                }
                # Requires property 'variable' to be a valid variable name
                try { & { Invoke-Expression "`$$($Properties['variable']) = `$null" } } catch {
                    Write-Warning "Invalid name"
                    return
                }
                return @{
                    Command = 'task.setvariable'
                    Message = $null
                    Properties = @{
                        Name       = $Properties['variable']
                        Value      = $Vso.Matches.Groups['line'].Value
                        IsSecret   = $Properties.ContainsKey('isSecret')
                        IsOutput   = $Properties.ContainsKey('isOutput')
                        IsReadOnly = $Properties.ContainsKey('isReadOnly')
                    }
                }
            }
            'task.setsecret' {
                # Requires no properties
                if ($Properties.Keys.Count -ne 0) {
                    return
                }
                # Requires message
                if (([string]::IsNullOrEmpty($Vso.Matches.Groups['line'].Value))) {
                    return
                }
                return @{
                    Command = 'task.setsecret'
                    Message = $null
                    Properties = @{
                        Value = $Vso.Matches.Groups['line'].Value
                    }
                }
            }
            'task.prependpath' {
                # Requires no properties
                if ($Properties.Keys.Count -ne 0) {
                    return
                }
                # Requires message
                if (([string]::IsNullOrEmpty($Vso.Matches.Groups['line'].Value))) {
                    return
                }
                return @{
                    Command = 'task.prependpath'
                    Message = $null
                    Properties = @{
                        Value = $Vso.Matches.Groups['line'].Value
                    }
                }
            }
            'task.uploadfile' {
                # Requires no properties
                if ($Properties.Keys.Count -ne 0) {
                    return
                }
                # Requires message
                if (([string]::IsNullOrEmpty($Vso.Matches.Groups['line'].Value))) {
                    return
                }
                return @{
                    Command = 'task.uploadfile'
                    Message = $null
                    Properties = @{
                        Value = $Vso.Matches.Groups['line'].Value
                    }
                }
                return $Return
            }
            'task.setprogress' {
                # Requires properties to be in 'value'
                if ($Properties.Keys | Where-Object { $_ -notin @('value') }) {
                    return
                }
                # Requires property 'value'
                if (-not ($Properties.ContainsKey('value'))) {
                    return
                }
                # Requires property 'value' to be an integer
                $percent = $null
                if (-not ([int]::TryParse($Properties['value'], [ref]$percent))) {
                    return
                }
                # Requires property 'value' to be between 0 and 100
                if ($percent -lt 0 -or $percent -gt 100) {
                    return
                }
                return @{
                    Command = 'task.setprogress'
                    Message = $Vso.Matches.Groups['line'].Value
                    Properties = @{
                        Value = $percent
                    }
                }
            }
            'task.logissue' {
                # Requires properties to be in 'value'
                if ($Properties.Keys | Where-Object { $_ -notin @('type','sourcepath','linenumber','colnumber','code') }) {
                    return
                }
                # Requires property 'type'
                if (-not ($Properties.ContainsKey('type'))) {
                    return
                }
                # Requires property 'type' to be 'warning' or 'error'
                if (-not ($Properties['type'] -in @('warning', 'error'))) {
                    return
                } else {
                    switch($Properties['type']) {
                        'warning' { $percent = 'warning' }
                        'error' { $percent = 'error' }
                    }
                }
                # Requires property 'linenumber' to an integer (if present)
                $tryparse = $null
                if ($Properties['linenumber'] -and -not ([int]::TryParse($Properties['linenumber'], [ref]$tryparse))) {
                    return
                } elseif($Properties['linenumber']) {
                    $LogLineNumber = $Properties['linenumber']
                } else {
                    $LogLineNumber = $null
                }
                # Requires property 'colnumber' to an integer (if present)
                $tryparse = $null
                if ($Properties['colnumber'] -and -not ([int]::TryParse($Properties['colnumber'], [ref]$tryparse))) {
                    return
                } elseif($Properties['colnumber']) {
                    $LogColNumber = $Properties['colnumber']
                } else {
                    $LogColNumber = $null
                }
                # Requires property 'code' to an integer (if present)
                $tryparse = $null
                if ($Properties['code'] -and -not ([int]::TryParse($Properties['code'], [ref]$tryparse))) {
                    return
                } elseif($Properties['code']) {
                    $LogCode = $Properties['code']
                } else {
                    $LogCode = $null
                }
                return @{
                    Command = 'task.logissue'
                    Message = $Vso.Matches.Groups['line'].Value
                    Properties = @{
                        Type = $Properties['type']
                        SourcePath = $Properties['sourcepath']
                        LineNumber = $LogLineNumber
                        ColNumber = $LogColNumber
                        Code = $LogCode
                    }
                }
            }
            'build.addbuildtag' {
                # Requires no properties
                if ($Properties.Keys.Count -ne 0) {
                    return
                }
                # Requires message
                if (([string]::IsNullOrEmpty($Vso.Matches.Groups['line'].Value))) {
                    return
                }
                return @{
                    Command = 'build.addbuildtag'
                    Message = $null
                    Properties = @{
                        Value = $Vso.Matches.Groups['line'].Value
                    }
                }
                return $Return
            }
        }
    }
    return
}