<#
    .SYNOPSIS
        Processes a VSO command object and updates the step output object.

    .PARAMETER vso
        The VSO command object to process.
        This object is initialized by the Expand-VsoCommandString function.
    
    .PARAMETER StepOutput
        The output of the step.

    .EXAMPLE
        '##vso[task.setcomplete result=Succeeded]Done' | Process-VsoCommand -StepOutput ([ref]$StepOutput)
#>
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]$vso,
    
    [Parameter(Mandatory)]
    [ref]$StepOutput
)
Process {
    switch ($vso.Command) {
        'task.complete' {
            $taskResult = [PSCustomObject]$vso.Properties
            $taskResult | Add-Member -MemberType NoteProperty -Name 'Message' -Value ($vso.Message)
            $StepOutput.Value.Result += , $taskResult
            return
        }
        'task.setvariable' {
            $taskVariable = [PSCustomObject]$vso.Properties
            $StepOutput.Value.Variable += , $taskVariable
            return
        }
        'task.setsecret' {
            $StepOutput.Value.Secret += , $vso.Properties.Value
            return
        }
        'task.prependpath' {
            $StepOutput.Value.Path += , $vso.Properties.Value
            return
        }
        default {
            Write-Warning "Unknown VSO Command: $($vso.Command)"
        }
    }
}