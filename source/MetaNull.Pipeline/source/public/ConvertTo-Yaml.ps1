<#
    .SYNOPSIS
        Converts a pipeline object into a YAML text file
#>
[CmdletBinding()]
[OutputType([string[]])]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateScript({$_.Id -is [guid]})]
    [pscustomobject]
    $Pipeline
)
Begin {
    Function Get-IndentedString {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory,Position = 0,ValueFromPipeline)]
            [AllowEmptyString()]
            [string]$String,

            [Parameter(Mandatory = $false, Position = 1)]
            [ValidateRange(0, 5)]
            [int]$Indentation = 0,

            [Parameter(Mandatory = $false)]
            [switch]$NewSection
        )
        if($NewSection.IsPresent -and $Indentation -gt 0) {
            $IndentationString = "$(' ' * (($Indentation - 1) * 2))- "
        } else {
            $IndentationString = ' ' * ($Indentation * 2)
        }
        "$IndentationString$String" | Write-Output
    }
}
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Get-Pipeline -Id $Id | Foreach-Object {
            $Pipeline = $_

            'trigger:' | Get-IndentedString
            'main' | Get-IndentedString -Indentation 1 -NewSection
            'pool:' | Get-IndentedString
            'vmImage: ''windows-latest''' | Get-IndentedString -Indentation 1
            'stages:' | Get-IndentedString
            $Pipeline.Stages | Foreach-Object {
                $Stage = $_
                "stage: $($Stage.Name)" | Get-IndentedString -Indentation 1 -NewSection
                "jobs:" | Get-IndentedString -Indentation 1
                $Stage.Jobs | Foreach-Object {
                    $Job = $_
                    "job: $($Job.Name)" | Get-IndentedString -Indentation 2 -NewSection
                    "steps:" | Get-IndentedString -Indentation 2
                    $Job.Steps | Foreach-Object {
                        $Step = $_
                        "task: Powershell@2" | Get-IndentedString -Indentation 3 -NewSection
                        "inputs:" | Get-IndentedString -Indentation 3
                        "targetType: 'inline'" | Get-IndentedString -Indentation 4
                        "pwsh: true" | Get-IndentedString -Indentation 4
                        "workingDirectory: '`$Build.SourcesDirectory'" | Get-IndentedString -Indentation 4
                        "script: |" | Get-IndentedString -Indentation 4
                        $Step.Commands | Foreach-Object {
                            $_ | Get-IndentedString -Indentation 5
                        }
                        "errorActionPreference: stop" | Get-IndentedString -Indentation 4
                        "failOnStderr: true" | Get-IndentedString -Indentation 4
                        "displayName: $($Step.Name)" | Get-IndentedString -Indentation 3
                        "env:" | Get-IndentedString -Indentation 3
                        #$Step.Env | Foreach-Object {
                        #    "($_.Name): ($_.Value)" | Get-IndentedString -Indentation 4
                        #}
                    }
                }
            }
        }
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}
