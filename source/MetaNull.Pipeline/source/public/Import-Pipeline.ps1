<#
    .SYNOPSIS
        Get Pipeline(s) from the registry
#>
[CmdletBinding(DefaultParameterSetName = 'Without')]
[OutputType([int])]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithPipeline')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithStage')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithJob')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithStep')]
    [ArgumentCompleter( { Resolve-PipelineId @args } )]
    [Alias('PipelineId')]
    [guid]
    $Id,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithStage')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithJob')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithStep')]
    [Alias('StageIndex')]
    [int]
    $Stage,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithJob')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithStep')]
    [Alias('JobIndex')]
    [int]
    $Job,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'WithStep')]
    [Alias('StepIndex')]
    [int]
    $Step
)
Begin {
    Function GetProperties {
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param(
            [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
            [Microsoft.Win32.RegistryKey] $Item
        )
        $Item | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* | Write-Output
    }
}
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if ($Id -and $Id -ne [guid]::Empty) {
            $PipelineItems = Get-Item "MetaNull:\Pipelines\$Id"
        } else {
            $PipelineItems = Get-ChildItem "MetaNull:\Pipelines" 
        }
        $PipelineItems | Foreach-Object {
            $PipelineProperties = $_ | GetProperties
            # $Pipeline | Add-Member -MemberType NoteProperty -Name Id -Value ([guid]::new(($_.Name | Split-Path -Leaf)))
            $PipelineProperties | Add-Member -MemberType NoteProperty -Name Stages -Value @()
            

            if ($Stage) {
                $StageItems = Get-Item "MetaNull:\Pipelines\$($PipelineProperties.Id)\Stages\$Stage"
            } else {
                $StageItems = Get-ChildItem "MetaNull:\Pipelines\$($PipelineProperties.Id)\Stages" 
            }

            $StageItems | ForEach-Object {
                $StageProperties = $_ | GetProperties
                $StageProperties | Add-Member -MemberType NoteProperty -Name Id -Value $PipelineProperties.Id
                $StageProperties | Add-Member -MemberType NoteProperty -Name Stage -Value ([int]::Parse(($_.Name | Split-Path -Leaf)))
                $StageProperties | Add-Member -MemberType NoteProperty -Name Jobs -Value @()

                Get-ChildItem "MetaNull:\Pipelines\$($StageProperties.Id)\Stages\$($StageProperties.Stage)\Jobs" | Where-Object {
                    (-not $Job) -or $_.Name -eq "$Job"
                } | ForEach-Object {
                    $JobProperties = $_ | GetProperties
                    $JobProperties | Add-Member -MemberType NoteProperty -Name Id -Value $StageProperties.Id
                    $JobProperties | Add-Member -MemberType NoteProperty -Name Stage -Value $StageProperties.Stage
                    $JobProperties | Add-Member -MemberType NoteProperty -Name Job -Value ([int]::Parse(($_.Name | Split-Path -Leaf)))
                    $JobProperties | Add-Member -MemberType NoteProperty -Name Steps -Value @()
                    
                    Get-ChildItem "MetaNull:\Pipelines\$($JobProperties.Id)\Stages\$($JobProperties.Stage)\Jobs\$($JobProperties.Job)\Steps" | Where-Object {
                        (-not $Step) -or $_.Name -eq "$Step"
                    } | ForEach-Object {
                        $StepProperties = $_ | GetProperties
                        $StepProperties | Add-Member -MemberType NoteProperty -Name Id -Value $JobProperties.Id
                        $StepProperties | Add-Member -MemberType NoteProperty -Name Stage -Value $JobProperties.Stage
                        $StepProperties | Add-Member -MemberType NoteProperty -Name Job -Value $JobProperties.Job
                        $StepProperties | Add-Member -MemberType NoteProperty -Name Step -Value ([int]::Parse(($_.Name | Split-Path -Leaf)))
                        
                        $JobProperties.Steps += $StepProperties
                    }

                    $StageProperties.Jobs += $JobProperties
                } 

                $PipelineProperties.Stages += $StageProperties
            }
            $PipelineProperties | Write-Output
        }
    }
    finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}