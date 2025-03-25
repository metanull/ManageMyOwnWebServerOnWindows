<#
    .SYNOPSIS
    Output the object to the VSO pipeline.

    .DESCRIPTION
    Output the object to the VSO pipeline.

    .PARAMETER OutputObject
    The object to output to the VSO pipeline.

    .PARAMETER StepOutput
    The output of the step.
#>
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$OutputObject,

    [Parameter(Mandatory)]
    [ref]$StepOutput
)
Process {
    # Detect if the received object is a VSO command
    $VsoCommand = $OutputObject | Expand-VsoCommandString
    if ($VsoCommand) {
        # If so, process the VSO command
        $VsoCommand | Invoke-VsoCommand -StepOutput ($StepOutput)
        return
    }
    # Replace secrets in the output
    $StepOutput.Value.Secret | Foreach-Object {
        $OutputObject = $OutputObject -replace $_, '***'
    }
    # Detect if the received object has VSO formatting instructions
    $VsoOutput = $OutputObject | Expand-VsoFormatString
    if ($VsoOutput -is [hashtable] -and $VsoOutput.ContainsKey('Format') -and $VsoOutput.ContainsKey('Message')) {
        # If so, output the object with the VSO formatting instructions
        switch ($VsoOutput.Format) {
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
    # Otherwise, output the object as is
    $VsoOutput | Write-Output
}