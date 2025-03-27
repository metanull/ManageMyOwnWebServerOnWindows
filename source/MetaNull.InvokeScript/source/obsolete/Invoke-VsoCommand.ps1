<#
    .SYNOPSIS
        Processes a VSO command object and returns its output.

    .PARAMETER vso
        The VSO command object to process.
        This object is initialized by the Expand-VsoCommandString function.
    
    .PARAMETER ScriptOutput
        The output of the vso command.
        If defined, the output of the script will be stored in this variable and the function will return a boolean indicating the success of the Script
        Otherwise, the output will be returned as a PSCustomObject
        If the ScriptOutput is already initialized, then the new values will be merged with the existing values.

    .EXAMPLE
        '##vso[task.setcomplete result=Succeeded]Done' | Process-VsoCommand -ScriptOutput ([ref]$ScriptOutput)
#>
[CmdletBinding(DefaultParameterSetName='Default')]
[OutputType([PSCustomObject], [bool])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]$vso,
    
    [Parameter(Mandatory, ParameterSetName='Reference')]
    [ref]$ScriptOutput
)
Process {
    # Initialize the step output
    $Return = [PSCustomObject]@{
        Result = [pscustomobject]@{
            Message = 'Not started'
            Result = 'Failed'
        }
        Variable = @()
        Secret = @()
        Path = @()
    }
    if($PSCmdlet.ParameterSetName -eq 'Reference') {
        Write-Debug "Returning a boolean, reporting the ScriptOutput by reference"
        if (-not ($ScriptOutput.Value -is [PSCustomObject] -and 
                  $ScriptOutput.Value.PSObject.Properties.Match('Result', 'Variable', 'Secret', 'Path').Count -eq 4)) {
            $ScriptOutput.Value = $Return
        } else {
            # If the ScriptOutput is already initialized, then we need to merge the new values...
            # Nothing to do here, as the $Return object is already initialized
        }
    } else {
        Write-Debug "Returning the ScriptOutput as a value"
        $ScriptOutput = [ref]$Return
    }

    $success = $false
    switch ($vso.Command) {
        'task.complete' {
            $taskResult = [PSCustomObject]$vso.Properties
            $taskResult | Add-Member -MemberType NoteProperty -Name 'Message' -Value ($vso.Message)
            $ScriptOutput.Value.Result += , $taskResult
            $success = $true
        }
        'task.setvariable' {
            $taskVariable = [PSCustomObject]$vso.Properties
            $ScriptOutput.Value.Variable += , $taskVariable
            $success = $true
        }
        'task.setsecret' {
            $ScriptOutput.Value.Secret += , $vso.Properties.Value
            $success = $true
        }
        'task.prependpath' {
            $ScriptOutput.Value.Path += , $vso.Properties.Value
            $success = $true
        }
        default {
            Write-Warning "Unknown VSO Command: $($vso.Command)"
        }
    }

    # Return the result
    if($PSCmdlet.ParameterSetName -eq 'Reference') {
        # Return a boolean indicating the success of the step
        return $success
    } else {
        # Return the output as a PSCustomObject
        return $ScriptOutput
    }
}