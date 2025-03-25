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
        Command    = $null
        Properties = @{}
        Message    = $null
    }

    # Check if the line is null or empty
    if ([string]::IsNullOrEmpty($line)) {
        return
    }
    # Check if the line is a VSO command
    $vso = $vso_regex.Match($line)
    if (-not ($vso.Success)) {
        # VSO Command not recognized
        return
    }
    # Parse properties
    $vsoProperties = $vso.Groups['properties'].Value.Trim() -split '\s*;\s*' | Where-Object { -not ([string]::IsNullOrEmpty($_)) } | ForEach-Object {
        $key, $value = $_.Trim() -split '\s*=\s*', 2
        @{"$key" = $value }
    }
    $vsoMessage = $vso.Groups['line'].Value
    switch ($vso.Groups['command']) {
        'task.complete' {
            # Requires properties to be in 'result'
            if ($vsoProperties.Keys | Where-Object { $_ -notin @('result') }) {
                return
            }
            # Requires property 'result'
            if (-not ($vsoProperties.ContainsKey('result'))) {
                return
            }
            # Requires property 'result' to be 'Succeeded', 'SucceededWithIssues', or 'Failed'
            if (-not ($vsoProperties['result'] -in @('Succeeded', 'SucceededWithIssues', 'Failed'))) {
                return
            }
            $vso_return.Command = 'task.complete'
            $vso_return.Message = $vsoMessage
            switch ($vsoProperties['result']) {
                'Succeeded' { $vso_return.Properties = @{Result = 'Succeeded' } }
                'SucceededWithIssues' { $vso_return.Properties = @{Result = 'SucceededWithIssues' } }
                'Failed' { $vso_return.Properties = @{Result = 'Failed' } }
                default {                   
                    return 
                }
            }
            return $vso_return
        }
        'task.setvariable' {
            # Requires properties to be in 'variable', 'isSecret', 'isOutput', and 'isReadOnly'
            if ($vsoProperties.Keys | Where-Object { $_ -notin @('variable', 'isSecret', 'isOutput', 'isReadOnly') }) {
                return
            }
            # Requires property 'variable'
            if (-not ($vsoProperties.ContainsKey('variable'))) {
                return
            }
            # Requires property 'variable' to be not empty
            if ([string]::IsNullOrEmpty($vsoProperties['variable'])) {
                return
            }
            # Requires property 'variable' to be a valid variable name
            try { & { Invoke-Expression "`$$($vsoProperties['variable']) = `$null" } } catch {
                return
            }
            $vso_return.Command = 'task.setvariable'
            $vso_return.Message = $null
            $vso_return.Properties = @{
                Name       = $vsoProperties['variable']
                Value      = $vsoMessage
                IsSecret   = $vsoProperties.ContainsKey('isSecret')
                IsOutput   = $vsoProperties.ContainsKey('isOutput')
                IsReadOnly = $vsoProperties.ContainsKey('isReadOnly')
            }
            return $vso_return
        }
        'task.setsecret' {
            # Requires no properties
            if ($vsoProperties.Keys.Count -ne 0) {
                return
            }
            # Requires message
            if (([string]::IsNullOrEmpty($vsoMessage))) {
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
            if ($vsoProperties.Keys.Count -ne 0) {
                return
            }
            # Requires message
            if (([string]::IsNullOrEmpty($vsoMessage))) {
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
            if ($vsoProperties.Keys.Count -ne 0) {
                return
            }
            # Requires message
            if (([string]::IsNullOrEmpty($vsoMessage))) {
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
            if ($vsoProperties.Keys | Where-Object { $_ -notin @('value') }) {
                return
            }
            # Requires property 'value'
            if (-not ($vsoProperties.ContainsKey('value'))) {
                return
            }
            # Requires property 'value' to be an integer
            $tryparse = $null
            if (-not ([int]::TryParse($vsoProperties['value'], [ref]$tryparse))) {
                return
            }
            $vso_return.Command = 'task.setprogress'
            $vso_return.Message = $vsoMessage
            $vso_return.Properties = @{Value = "$tryparse" }
            return $vso_return
        }
    }

    # VSO Command not recognized
    return
}