<#
    .SYNOPSIS
        Execute a pipeline's task
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [string[]] $Commands
)
Process {
    $Actions = [PSCustomObject]@{
        Variable = @()
        Result = @()
        Secret = @()
        Path = @()
    }
    $SetVariable.Value = @()        # An Array of Objects
    $SetResult.Value = @()          # An Array of Objects
    $SetSecret.Value = @()          # An Array of Strings

    $vso = Expand-VsoCommandString -line $InputObject
    if($vso) {
        switch($vso.Command) {
            'task.complete' {
                # Append the result to the SetResult array
                $taskResult = [PSCustomObject]$vso.Properties
                $taskResult | Add-Member -MemberType NoteProperty -Name 'Message' -Value ($vso.Message)
                $Actions.Result += ,$taskResult
                return
            }
            'task.setvariable' {
                $taskVariable = [PSCustomObject]$vso.Properties
                $Actions.Variable += ,$taskVariable
                return
            }
            'task.setsecret' {
                $Actions.Secret += ,$vso.Properties.Value
                return
            }
            'task.prependpath' {
                $Actions.Path += ,$vso.Properties.Value
                # [Environment]::SetEnvironmentVariable('Path', "$($vso.Properties.Value);$($env:Path)", 'User')
                return
            }
            default {
                throw "Unknown VSO Command: $($vso.Command)"
            }
        }
        return
    }

    $vso = Expand-VsoFormatString -line $InputObject
    if($vso) {
        switch($vso.Format) {
            'group' {
                Write-Host "[+] $($vso.Message)" -ForegroundColor Magenta
            }
            'endgroup' {
                Write-Host "[-] $($vso.Message)" -ForegroundColor Magenta
            }
            'section' {
                Write-Host "$($vso.Message)" -ForegroundColor Cyan
            }
            'command' {
                Write-Host "$($vso.Message)" -ForegroundColor Yellow
            }
            'warning' {
                Write-Host "WARNING: $($vso.Message)" -ForegroundColor Yellow
            }
            'error' {
                Write-Host "ERROR: $($vso.Message)" -ForegroundColor Red
            }
            default {
                throw "Unknown VSO Format: $($vso.Format)"
            }
        }
        return
    }
}
End {
    
}