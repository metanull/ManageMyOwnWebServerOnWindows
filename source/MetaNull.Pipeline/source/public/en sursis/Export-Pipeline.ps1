<#
    .SYNOPSIS
        Save a pipeline in the Registry
#>
[CmdletBinding()]
[OutputType([guid])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateScript({-not [string]::IsNullOrEmpty($_.Name)})]
    [pscustomobject]
    $Pipeline,

    [Parameter(Mandatory = $false)]
    [switch] $Force = $false
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if ($null -ne $Pipeline.Id -and $Pipeline.Id -ne [guid]::Empty) {
            Write-Warning "Pipeline Id is not empty. This will be ignored and a new Id will be generated."
        }

        $Existing = Get-ChildItem "MetaNull:\Pipelines" | Where-Object {($_ | Get-ItemProperty | Select-Object -ExpandProperty Name | Where-Object { $_ -eq $Pipeline.Name})}
        if ($Existing) {
            if ($Force.IsPresent -and $Force) {
                $Existing | Remove-Item -Recurse -Force
            } else {
                throw "Pipeline with name $($Pipeline.Name) already exists. Use -Force to overwrite."
            }
        }
        $Pipeline | Add-Member -MemberType NoteProperty -Name Id -Value (New-Guid) -Force

        $PipelineItem = New-Item "MetaNull:\Pipelines\$($Pipeline.Id)"
        $Pipeline | Get-Member -MemberType NoteProperty | Where-Objecct { $_.Name -notin 'Stages' } | ForEach-Object {
            $PipelineItem | New-ItemProperty -Name $_.Name -Value $Pipeline.$($_.Name)
        }
        $Pipeline.Stages | Foreach-Object -Begin {$StageIndex = -1} -Process{
            $StageIndex ++
            $StageItem = New-Item "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$StageIndex"
            $_ | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notin 'Stage','Jobs' } | ForEach-Object {
                $StageItem | New-ItemProperty -Name $_.Name -Value $_.$($_.Name)
            }
            $_.Jobs | Foreach-Object -Begin {$JobIndex = -1} -Process {
                $JobIndex ++
                $JobItem = New-Item "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$StageIndex\Jobs\$JobIndex"
                $_ | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notin 'Job','Steps' } | ForEach-Object {
                    $JobItem | New-ItemProperty -Name $_.Name -Value $_.$($_.Name)
                }
                $_.Steps | Foreach-Object -Begin {$StepIndex = -1} -Process {
                    $StepIndex ++
                    $StepItem = New-Item "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$StageIndex\Jobs\$JobIndex)\Steps\$StepIndex"
                    $_ | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notin 'Step','commands'} | ForEach-Object {
                        $StepItem | New-ItemProperty -Name $_.Name -Value $_.$($_.Name)
                    }
                    if ($_.Commands) {
                        $Commands = $_.Commands
                    } else {
                        $Commands = @()
                    }
                    $StepItem | New-ItemProperty -Name Commands -Value $Commands -PropertyType MultiString
                }
            }
        }
        return $Pipeline.Id
    }
    finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}