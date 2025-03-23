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
                    Index = 1
                    Name = 'STAGE:1.1'

                    Jobs = @(
                        @{
                            Index = 1
                            Name = 'JOB:1.1.1'

                            Tasks = @(
                                @{
                                    Index = 1
                                    Name = 'TASK:1.1.1.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "One"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'One'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:1.1.1.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Two"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Two'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:1.1.1.3'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Three"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Three'
                                    )
                                }
                            )
                        }
                        @{
                            Index = 2
                            Name = 'JOB:1.1.2'

                            Tasks = @(
                                @{
                                    Index = 1
                                    Name = 'TASK:1.1.2.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Four"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Four'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:1.1.2.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Five"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Five'
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    Index = 2
                    Name = 'STAGE:1.2'

                    Jobs = @(
                        @{
                            Index = 1
                            Name = 'JOB:1.2.1'

                            Tasks = @(
                                @{
                                    Index = 1
                                    Name = 'TASK:1.2.1.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Six"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Six'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:1.2.1.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Seven"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Seven'
                                    )
                                }
                                @{
                                    Index = 3
                                    Name = 'TASK:1.2.1.3'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Eight"'
                                    )
                                    Output = @(
                                        'Hello'
                                        'Eight'
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
                    Index = 1
                    Name = 'STAGE:2.1'

                    Jobs = @(
                        @{
                            Index = 1
                            Name = 'JOB:2.1.1'

                            Tasks = @(
                                @{
                                    Index = 1
                                    Name = 'TASK:2.1.1.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "One"'
                                    )
                                    Output = @(
                                        'World'
                                        'One'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:2.1.1.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Two"'
                                    )
                                    Output = @(
                                        'World'
                                        'Two'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:2.1.1.3'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Three"'
                                    )
                                    Output = @(
                                        'World'
                                        'Three'
                                    )
                                }
                            )
                        }
                        @{
                            Index = 2
                            Name = 'JOB:2.1.2'

                            Tasks = @(
                                @{
                                    Index = 1
                                    Name = 'TASK:2.1.2.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Four"'
                                    )
                                    Output = @(
                                        'World'
                                        'Four'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:2.1.2.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Five"'
                                    )
                                    Output = @(
                                        'World'
                                        'Five'
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    Index = 2
                    Name = 'STAGE:2.2'

                    Jobs = @(
                        @{
                            Index = 1
                            Name = 'JOB:2.2.1'

                            Tasks = @(
                                @{
                                    Index = 1
                                    Name = 'TASK:2.2.1.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Six"'
                                    )
                                    Output = @(
                                        'World'
                                        'Six'
                                    )
                                }
                                @{
                                    Index = 2
                                    Name = 'TASK:2.2.1.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Seven"'
                                    )
                                    Output = @(
                                        'World'
                                        'Seven'
                                    )
                                }
                                @{
                                    Index = 3
                                    Name = 'TASK:2.2.1.3'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Eight"'
                                    )
                                    Output = @(
                                        'World'
                                        'Eight'
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
                        $_.Key -ne 'Tasks'
                    } | ForEach-Object {
                        $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                    }
                    $_.Tasks | Foreach-Object {
                        $Task = $_
                        $Item = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Tasks\$($Task.Index)" -Force
                        $_.GetEnumerator() | Where-Object {
                            $_.Key -notin 'Commands','Output'
                        } | ForEach-Object {
                            $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                        }
                        $Item | New-ItemProperty -Name 'Commands' -Value $Task.Commands -Type MultiString | Out-Null
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
                if(-not ($_.Index)) {
                    throw "TestData[$pipelineIndex].Stages[$stageIndex].Index was empty"
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
                    if(-not ($_.Index)) {
                        throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Index was empty"
                    }
                    if(-not ($_.Name)) {
                        throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Name was empty"
                    }
                    if(-not ($_.Tasks)) {
                        throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks was empty"
                    }
                    $taskIndex = -1
                    $_.Tasks | Foreach-Object {
                        $taskIndex += 1
                        if(-not ($_.Index)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks[$taskIndex].Index was empty"
                        }
                        if(-not ($_.Name)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks[$taskIndex].Name was empty"
                        }
                        if(-not ($_.Commands)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks[$taskIndex].Commands was empty"
                        }
                        if(-not ($_.Output)) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks[$taskIndex].Output was empty"
                        }
                        if($_.Commands.Count -ne $_.Output.Count) {
                            throw "TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks[$taskIndex].Commands.Count doesn't match TestData[$pipelineIndex].Stages[$stageIndex].Jobs[$jobIndex].Tasks[$taskIndex].Output.Count"
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