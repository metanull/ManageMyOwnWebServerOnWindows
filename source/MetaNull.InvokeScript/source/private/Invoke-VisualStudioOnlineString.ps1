<#
    .SYNOPSIS
        Process Visual Studio Online strings.

    .DESCRIPTION
        Process Visual Studio Online strings.

    .PARAMETER InputString
        The object to output to the VSO pipeline.

    .PARAMETER ScriptOutput
        The output of the step.
#>
[CmdletBinding(DefaultParameterSetName='Default')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored pipeline output')]
[OutputType([string])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [string]$InputString,

    [Parameter(Mandatory = $false)]
    [ref]$ScriptOutput
)
Process {
    # Initialize the State variable, if not already initialized
    if($null -eq $ScriptOutput.Value) {
        $ScriptOutput.Value = [pscustomobject]@{
            Result = [pscustomobject]@{
                Message = 'Not started'
                Result = 'Failed'
            }
            Variable = @()
            Secret = @()
            Path = @()
            Upload = @()
            Log = @()
            Error = @()
            Retried = 0
        }
    }

    # Detect if the received object is a VSO command or VSO format string
    $VsoResult = $InputString | ConvertFrom-VisualStudioOnlineString
    if(-not ($VsoResult)) {
        # Input is just a string, no procesing required

        # Replace any secrets in the output
        $ScriptOutput.Value.Secret | Foreach-Object {
            $InputString = $InputString -replace [Regex]::Escape($_), '***'
        }
        # Output the message as is
        $InputString | Write-Output
        return
    }

    if($VsoResult.Format) {
        # Input is a VSO format string, no procesing required, but output the message according to the format

        # Replace any secrets in the output
        $ScriptOutput.Value.Secret | Foreach-Object {
            $VsoResult.Message = $VsoResult.Message -replace [Regex]::Escape($_), '***'
        }

        # Output the message according to the format
        switch ($VsoResult.Format) {
            'group' {
                Write-Host "[+] $($VsoResult.Message)" -ForegroundColor Magenta
                return
            }
            'endgroup' {
                Write-Host "[-] $($VsoResult.Message)" -ForegroundColor Magenta
                return
            }
            'section' {
                Write-Host "$($VsoResult.Message)" -ForegroundColor Cyan
                return
            }
            'warning' {
                Write-Host "WARNING: $($VsoResult.Message)" -ForegroundColor Yellow
                return
            }
            'error' {
                Write-Host "ERROR: $($VsoResult.Message)" -ForegroundColor Red
                return
            }
            'debug' {
                Write-Host "DEBUG: $($VsoResult.Message)" -ForegroundColor Gray
                return
            }
            'command' {
                Write-Host "$($VsoResult.Message)" -ForegroundColor Blue
                return
            }
            default {
                # Unknown format/not implemented
                Write-Warning "Format [$($VsoResult.Format)] is not implemented"

                # Do not return! Output is processed further
            }
        }
    }

    if($VsoResult.Command) {
        # Input is a VSO command, process it
        switch($VsoResult.Command) {
            'task.complete' {
                Write-Debug "Task complete: $($VsoResult.Properties.Result) - $($VsoResult.Message)"
                $ScriptOutput.Value.Result.Result = $VsoResult.Properties.Result
                $ScriptOutput.Value.Result.Message = $VsoResult.Message
                return
            }
            'task.setvariable' {
                Write-Debug "Task set variable: $($VsoResult.Properties.Variable) = $($VsoResult.Properties.Value)"
                $ScriptOutput.Value.Variable += ,[pscustomobject]$VsoResult.Properties
                return
            }
            'task.setsecret' {
                Write-Debug "Task set secret: $($VsoResult.Properties.Value)"
                $ScriptOutput.Value.Secret += ,$VsoResult.Properties.Value
                return
            }
            'task.prependpath' {
                Write-Debug "Task prepend path: $($VsoResult.Properties.Value)"
                $ScriptOutput.Value.Path += ,$VsoResult.Properties.Value
                return
            }
            'task.uploadfile' {
                Write-Debug "Task upload file: $($VsoResult.Properties.Value)"
                $ScriptOutput.Value.Upload += ,$VsoResult.Properties.Value
                return
            }
            'task.logissue' {
                Write-Debug "Task log issue: $($VsoResult.Properties.Type) - $($VsoResult.Message)"
                $ScriptOutput.Value.Log += ,[pscustomobject]$VsoResult.Properties
                return
            }
            'task.setprogress' {
                Write-Debug "Task set progress: $($VsoResult.Properties.Value) - $($VsoResult.Message)"
                $PercentString = "$($VsoResult.Properties.Percent)".PadLeft(3,' ')
                Write-Host "$($VsoResult.Message) - $PercentString %" -ForegroundColor Green
                return
            }
            default {
                # Not implemented
                Write-Debug "Command [$($VsoResult.Command)] is not implemented"

                # Do not return! Output is processed further
            }
        }
    }
    
    # Replace any secrets in the output
    $ScriptOutput.Value.Secret | Foreach-Object {
        $InputString = $InputString -replace [Regex]::Escape($_), '***'
    }

    # Unknown input, output as is
    Write-Warning "Error processing input: $InputString"
    $InputString | Write-Output
}