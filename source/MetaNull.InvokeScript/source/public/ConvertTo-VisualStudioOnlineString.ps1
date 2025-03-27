[CmdletBinding(DefaultParameterSetName='Default')]
[OutputType([string])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $Message
)
Begin {
    $VisualStudioOnlineExpressions = @{
        Command = '^##vso\[(?<command>[\S]+)(?<properties>[^\]]*)\](?<line>.*)$'
        Format = '^##\[(?<format>group|endgroup|section|warning|error|debug|command)\](?<line>.*)$'
    }
}
Process {
    # Check if the line is null or empty
    if ([string]::IsNullOrEmpty($String)) {
        return
    }
    
    # Evaluate each regular expression against the received String
    $Vso = @{
        Type = $null
        Expression = $null
        Matches = $null
    }
    $VisualStudioOnlineExpressions.GetEnumerator() | Foreach-Object {
        $RxExpression = [regex]::new($_)
        $Rx = $RxExpression.Match($String)
        if ($Rx.Success) {
            $Vso.Type = $_.Key
            $Vso.Expression = $_.Value
            $Vso.Matches = $Rx.Groups
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
        $Properties = $Vso.Matches.Groups['properties'].Value.Trim() -split '\s*;\s*' | Where-Object { 
            -not ([string]::IsNullOrEmpty($_)) 
        } | ForEach-Object {
            $key, $value = $_.Trim() -split '\s*=\s*', 2
            @{"$key" = $value }
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
                    return
                }
                # Requires property 'variable'
                if (-not ($Properties.ContainsKey('variable'))) {
                    return
                }
                # Requires property 'variable' to be not empty
                if ([string]::IsNullOrEmpty($Properties['variable'])) {
                    return
                }
                # Requires property 'variable' to be a valid variable name
                try { & { Invoke-Expression "`$$($Properties['variable']) = `$null" } } catch {
                    return
                }
                return @{
                    Command = 'task.setvariable'
                    Message = $Vso.Matches.Groups['line'].Value
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
                $tryparse = $null
                if (-not ([int]::TryParse($Properties['value'], [ref]$tryparse))) {
                    return
                }
                return @{
                    Command = 'task.setprogress'
                    Message = $Vso.Matches.Groups['line'].Value
                    Properties = @{
                        Value = "$tryparse"
                    }
                }
                return $Return
            }
        }
    }
    return
}