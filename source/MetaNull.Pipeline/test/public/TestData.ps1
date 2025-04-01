# Mock Module Initialization, create the test registry key
$PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.Pipeline'
New-Item -Force -Path $PSDriveRoot\Pipelines -ErrorAction SilentlyContinue  | Out-Null
$MetaNull = @{
    Pipeline = @{
        PSDriveRoot = $PSDriveRoot
        Lock = New-Object Object
        Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
    }
}

$TestData = @{
    ExportParameters = @{
        OutputDirectory = "$($env:TEMP)\MetaNull.Pipeline\Output"
    }
    Pipelines = @(
        @{
            Id = (New-Guid)
            Name = 'PIPELINE:1'

            Stages = @(
                @{
                    Stage = 1
                    Name = 'STAGE:1.1'

                    Jobs = @(
                        @{
                            Job = 1
                            Name = 'JOB:1.1.1'

                            Steps = @(
                                @{
                                    Step = 1
                                    Name = 'STEP:1.1.1.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "One"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:1.1.1.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Two"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:1.1.1.3'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Three"'
                                    )
                                }
                            )
                        }
                        @{
                            Job = 2
                            Name = 'JOB:1.1.2'

                            Steps = @(
                                @{
                                    Step = 1
                                    Name = 'STEP:1.1.2.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Four"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:1.1.2.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Five"'
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    Stage = 2
                    Name = 'STAGE:1.2'

                    Jobs = @(
                        @{
                            Job = 1
                            Name = 'JOB:1.2.1'

                            Steps = @(
                                @{
                                    Step = 1
                                    Name = 'STEP:1.2.1.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Six"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:1.2.1.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Seven"'
                                    )
                                }
                                @{
                                    Step = 3
                                    Name = 'STEP:1.2.1.3'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Eight"'
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
        @{
            Id = (New-Guid)
            Name = 'PIPELINE:2'

            Stages = @(
                @{
                    Stage = 1
                    Name = 'STAGE:2.1'

                    Jobs = @(
                        @{
                            Job = 1
                            Name = 'JOB:2.1.1'

                            Steps = @(
                                @{
                                    Step = 1
                                    Name = 'STEP:2.1.1.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "One"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:2.1.1.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Two"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:2.1.1.3'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Three"'
                                    )
                                }
                            )
                        }
                        @{
                            Job = 2
                            Name = 'JOB:2.1.2'

                            Steps = @(
                                @{
                                    Step = 1
                                    Name = 'STEP:2.1.2.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Four"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:2.1.2.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Five"'
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    Stage = 2
                    Name = 'STAGE:2.2'

                    Jobs = @(
                        @{
                            Job = 1
                            Name = 'JOB:2.2.1'

                            Steps = @(
                                @{
                                    Step = 1
                                    Name = 'STEP:2.2.1.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Six"'
                                    )
                                }
                                @{
                                    Step = 2
                                    Name = 'STEP:2.2.1.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Seven"'
                                    )
                                }
                                @{
                                    Step = 3
                                    Name = 'STEP:2.2.1.3'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Eight"'
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
    )
}

Function DestroyTestData {
    Remove-Item -Force -Recurse -Path MetaNull:\ -ErrorAction SilentlyContinue  | Out-Null
    Remove-PSDrive -Name MetaNull -Scope Script -ErrorAction SilentlyContinue
}

Function RemoveTestData {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Remove-Item -Force -Recurse -Path MetaNull:\Pipelines\* -ErrorAction SilentlyContinue  | Out-Null
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
Function InsertTestData {
    param($TestData)

    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {

        $TestData.Pipelines | Foreach-Object {
            $Pipeline = $_
            $Id = $Pipeline.Id
            $Properties = $Pipeline
            New-Item "MetaNull:\Pipelines\$Id" -Force | Out-Null
            $Item = Get-Item "MetaNull:\Pipelines\$Id"
            $Properties.GetEnumerator() | Where-Object {
                $_.Key -ne 'Stages'
            } | ForEach-Object {
                $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
            }
            $_.Stages | Foreach-Object {
                $Stage = $_
                $Item = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)" -Force
                $_.GetEnumerator() | Where-Object {
                    $_.Key -ne 'Jobs'
                } | ForEach-Object {
                    $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                }
                $_.Jobs | Foreach-Object {
                    $Job = $_
                    $Item = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)\Jobs\$($Job.Index)" -Force
                    $_.GetEnumerator() | Where-Object {
                        $_.Key -ne 'Steps'
                    } | ForEach-Object {
                        $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                    }
                    $_.Steps | Foreach-Object {
                        $Step = $_
                        $Item = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Steps\$($Step.Index)" -Force
                        $_.GetEnumerator() | Where-Object {
                            $_.Key -notin 'Commands','Output'
                        } | ForEach-Object {
                            $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                        }
                        $Item | New-ItemProperty -Name 'Commands' -Value $Step.Commands -Type MultiString | Out-Null
                    }
                }
            }
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
Function ValidateTestData {
    param($TestData)
    
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if( -not (Get-PSDrive -Name 'MetaNull')) {
            throw 'PSDrive MetaNull: is not defined'
        }
        if( -not (Test-Path MetaNull:\Pipelines)) {
            throw 'Path MetaNull:\Pipelines was not found'
        }
        if(-not ($TestData.Pipelines)) {
            throw "TestData.Pipelines was empty"
        }
        $pipelineIndex = -1
        $TestData.Pipelines | Foreach-Object {
            $pipelineIndex += 1
            if(-not ($_.Id)) {
                throw "TestData[$pipelineIndex].Id was empty"
            }
            if(-not ($_.Name)) {
                throw "TestData[$pipelineIndex].Name was empty"
            }
            if(-not ($_.Stages)) {
                throw "TestData[$pipelineIndex].Stages was empty"
            }
            $stageIndex = -1
            $_.Stages | Foreach-Object {
                $stageIndex += 1
                if(-not ($_.Stage)) {
                    throw "TestData[$pipelineIndex].Stages[$stageIndex].Stage was empty"
                }
                if(-not ($_.Name)) {
                    throw "TestData[$pipelineIndex].Stages[$stageIndex].Name was empty"
                }
                if(-not ($_.Jobs)) {
                    throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs was empty"
                }
                $jobIndex = -1
                $_.Jobs | Foreach-Object {
                    $jobIndex += 1
                    if(-not ($_.Job)) {
                        throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Job was empty"
                    }
                    if(-not ($_.Name)) {
                        throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Name was empty"
                    }
                    if(-not ($_.Steps)) {
                        throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps was empty"
                    }
                    $stepIndex = -1
                    $_.Steps | Foreach-Object {
                        $stepIndex += 1
                        if(-not ($_.Step)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps[$stepIndex].Step was empty"
                        }
                        if(-not ($_.Name)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps[$stepIndex].Name was empty"
                        }
                        if(-not ($_.Commands)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps[$stepIndex].Commands was empty"
                        }
                        if(-not ($_.Output)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps[$stepIndex].Output was empty"
                        }
                        if($_.Commands.Count -ne $_.Output.Count) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps[$stepIndex].Commands.Count doesn't match TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Steps[$stepIndex].Output.Count"
                        }
                    }
                }
            }
        }
        return $true
    } catch {
        Write-Warning $_.Exception.ToString()
        return $false
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}