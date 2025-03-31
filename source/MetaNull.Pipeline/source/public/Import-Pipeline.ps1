<#
    .SYNOPSIS
        Get Pipeline(s) from the registry
#>
[CmdletBinding(DefaultParameterSetName = 'Pipeline')]
[OutputType([int])]
param(
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Pipeline')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Stage')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Job')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Step')]
    [SupportsWildcards()]
    [ArgumentCompleter( { Resolve-PipelineId @args } )]
    [Alias('PipelineId')]
    [guid]
    $Id,

    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Stage')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Job')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Step')]
    [Alias('StageIndex')]
    [int]
    $Stage,

    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Job')]
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Step')]
    [Alias('JobIndex')]
    [int]
    $Job,

    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName, ParameterSetName = 'Step')]
    [Alias('StepIndex')]
    [AllowNull()]
    [int]
    $Step = $null
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
        $IdFilter = '*'
        if ($Id -ne [guid]::Empty) {
            $IdFilter = $Id.ToString()
        }

        Get-ChildItem "MetaNull:\Pipelines\$IdFilter" | Foreach-Object {
            $Pipeline = $_ | GetProperties
            $Pipeline | Add-Member -MemberType NoteProperty -Name Id -Value [Guid]::new($_.Name)
            $Pipeline | Add-Member -MemberType NoteProperty -Name Stages -Value @()
            
            Get-ChildItem "MetaNull:\Pipelines\$($Pipeline.Id)\Stages" | Where-Object {
                $null -eq $Stage -or $_.Name -eq "$Stage"
            } | ForEach-Object {
                $Stage = $_ | GetProperties
                $Stage | Add-Member -MemberType NoteProperty -Name Id -Value $Pipeline.Id
                $Stage | Add-Member -MemberType NoteProperty -Name Stage -Value ([int]::Parse($_.Name))
                $Stage | Add-Member -MemberType NoteProperty -Name Jobs -Value @()

                Get-ChildItem "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$($Stage.Stage)\Jobs" | Where-Object {
                    $null -eq $Job -or $_.Name -eq "$Job"
                } | ForEach-Object {
                    $Job = $_ | GetProperties
                    $Job | Add-Member -MemberType NoteProperty -Name Id -Value $Stage.Id
                    $Job | Add-Member -MemberType NoteProperty -Name Stage -Value $Stage.Stage
                    $Job | Add-Member -MemberType NoteProperty -Name Job -Value ([int]::Parse($_.Name))
                    $Job | Add-Member -MemberType NoteProperty -Name Jobs -Value @()
                    
                    Get-ChildItem "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$($Stage.Stage)\Jobs\$($Job.Job)\Steps" | Where-Object {
                        $null -eq $Step -or $_.Name -eq "$Step"
                    } | ForEach-Object {
                        $Step = $_ | GetProperties
                        $Step | Add-Member -MemberType NoteProperty -Name Id -Value $Job.Id
                        $Step | Add-Member -MemberType NoteProperty -Name Stage -Value $Job.Stage
                        $Step | Add-Member -MemberType NoteProperty -Name Job -Value $Job.Job
                        $Step | Add-Member -MemberType NoteProperty -Name Step -Value ([int]::Parse($_.Name))
                        
                        $Job.Steps += $Step
                    }

                    $Stage.Jobs += $Job
                } 

                $Pipeline.Stages += $Stage
            }
            $Pipeline | Add-Member -MemberType NoteProperty -Name Stages -Value @()
            $Pipeline | Write-Output
        }
    }
    finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}