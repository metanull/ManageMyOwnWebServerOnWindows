<#
    .SYNOPSIS
        Processes a VSO command object and updates the step output object.

    .PARAMETER vso
        The VSO command object to process.
        This object is initialized by the Expand-VsoCommandString function.
    
    .PARAMETER ScriptOutput
        The output of the step.

    .EXAMPLE
        '##vso[task.setcomplete result=Succeeded]Done' | Process-VsoCommand -ScriptOutput ([ref]$ScriptOutput)
#>
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]$vso,
    
    [Parameter(Mandatory)]
    [ref]$ScriptOutput
)
Process {
    switch ($vso.Command) {
        'task.complete' {
            $taskResult = [PSCustomObject]$vso.Properties
            $taskResult | Add-Member -MemberType NoteProperty -Name 'Message' -Value ($vso.Message)
            $ScriptOutput.Value.Result += , $taskResult
            return
        }
        'task.setvariable' {
            $taskVariable = [PSCustomObject]$vso.Properties
            $ScriptOutput.Value.Variable += , $taskVariable
            return
        }
        'task.setsecret' {
            $ScriptOutput.Value.Secret += , $vso.Properties.Value
            return
        }
        'task.prependpath' {
            $ScriptOutput.Value.Path += , $vso.Properties.Value
            return
        }
        default {
            Write-Warning "Unknown VSO Command: $($vso.Command)"
        }
    }
}