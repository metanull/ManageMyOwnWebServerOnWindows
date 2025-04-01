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
                    Name = 'STAGE:1.1'

                    Jobs = @(
                        @{
                            Name = 'JOB:1.1.1'

                            Steps = @(
                                @{
                                    Name = 'STEP:1.1.1.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "One"'
                                    )
                                }
                                @{
                                    Name = 'STEP:1.1.1.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Two"'
                                    )
                                }
                                @{
                                    Name = 'STEP:1.1.1.3'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Three"'
                                    )
                                }
                            )
                        }
                        @{
                            Name = 'JOB:1.1.2'

                            Steps = @(
                                @{
                                    Name = 'STEP:1.1.2.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Four"'
                                    )
                                }
                                @{
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
                    Name = 'STAGE:1.2'

                    Jobs = @(
                        @{
                            Name = 'JOB:1.2.1'

                            Steps = @(
                                @{
                                    Name = 'STEP:1.2.1.1'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Six"'
                                    )
                                }
                                @{
                                    Name = 'STEP:1.2.1.2'
                                    Commands = @(
                                        'Write-Output "Hello"'
                                        'Write-Output "Seven"'
                                    )
                                }
                                @{
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
                    Name = 'STAGE:2.1'

                    Jobs = @(
                        @{
                            Name = 'JOB:2.1.1'

                            Steps = @(
                                @{
                                    Name = 'STEP:2.1.1.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "One"'
                                    )
                                }
                                @{
                                    Name = 'STEP:2.1.1.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Two"'
                                    )
                                }
                                @{
                                    Name = 'STEP:2.1.1.3'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Three"'
                                    )
                                }
                            )
                        }
                        @{
                            Name = 'JOB:2.1.2'

                            Steps = @(
                                @{
                                    Name = 'STEP:2.1.2.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Four"'
                                    )
                                }
                                @{
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
                    Name = 'STAGE:2.2'

                    Jobs = @(
                        @{
                            Name = 'JOB:2.2.1'

                            Steps = @(
                                @{
                                    Name = 'STEP:2.2.1.1'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Six"'
                                    )
                                }
                                @{
                                    Name = 'STEP:2.2.1.2'
                                    Commands = @(
                                        'Write-Output "World"'
                                        'Write-Output "Seven"'
                                    )
                                }
                                @{
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
            $PipelineItem = Get-Item "MetaNull:\Pipelines\$Id"
            $Properties.GetEnumerator() | Where-Object {
                $_.Key -ne 'Stages'
            } | ForEach-Object {
                $PipelineItem | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
            }
            $_.Stages | Foreach-Object -Begin {$StageIndex = 0} -Process {
                $StageIndex ++
                $Stage = $_
                $StageItem = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($StageIndex)" -Force
                $_.GetEnumerator() | Where-Object {
                    $_.Key -ne 'Jobs'
                } | ForEach-Object {
                    $StageItem | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                }
                $_.Jobs | Foreach-Object -Begin {$JobIndex = 0} -Process {
                    $JobIndex ++
                    $Job = $_
                    $JobItem = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($StageIndex)\Jobs\$($JobIndex)" -Force
                    $_.GetEnumerator() | Where-Object {
                        $_.Key -ne 'Steps'
                    } | ForEach-Object {
                        $JobItem | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                    }
                    $_.Steps | Foreach-Object -Begin {$StepIndex = 0} -Process {
                        $StepIndex ++
                        $Step = $_
                        $StepItem = New-Item -Path "MetaNull:\Pipelines\$Id\Stages\$($StageIndex)\Jobs\$($JobIndex)\Steps\$($StepIndex)" -Force
                        $StepItem | New-ItemProperty -Name 'Commands' -Value $Step.Commands -Type MultiString | Out-Null
                        $_.GetEnumerator() | Where-Object {
                            $_.Key -notin 'Commands','Output'
                        } | ForEach-Object {
                            $StepItem | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                        }
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
        $TestData.Pipelines | Foreach-Object -Begin { $PipelineIndex = -1} -Process {
            $PipelineIndex ++
            if(-not ($_.Id)) {
                throw "TestData[$PipelineIndex].Id was empty"
            }
            if(-not ($_.Name)) {
                throw "TestData[$PipelineIndex].Name was empty"
            }
            if(-not ($_.Stages)) {
                throw "TestData[$PipelineIndex].Stages was empty"
            }
            $_.Stages | Foreach-Object -Begin { $StageIndex = -1} -Process {
                $StageIndex ++
                if(-not ($_.Name)) {
                    throw "TestData[$PipelineIndex].Stages[$StageIndex].Name was empty"
                }
                if(-not ($_.Jobs)) {
                    throw "TestData[$PipelineIndex].Stages[$StageIndex].Jobs was empty"
                }
                $_.Jobs | Foreach-Object -Begin { $JobIndex = -1} -Process {
                    $JobIndex ++
                    if(-not ($_.Name)) {
                        throw "TestData[$PipelineIndex].Stages[$StageIndex].Jobs[$JobIndex].Name was empty"
                    }
                    if(-not ($_.Steps)) {
                        throw "TestData[$PipelineIndex].Stages[$StageIndex].Jobs[$JobIndex].Steps was empty"
                    }
                    $_.Steps | Foreach-Object -Begin { $StepIndex = -1} -Process {
                        $StepIndex ++
                        if(-not ($_.Name)) {
                            throw "TestData[$PipelineIndex].Stages[$StageIndex].Jobs[$JobIndex].Steps[$StepIndex].Name was empty"
                        }
                        if(-not ($_.Commands)) {
                            throw "TestData[$PipelineIndex].Stages[$StageIndex].Jobs[$JobIndex].Steps[$StepIndex].Commands was empty"
                        }
                    }
                }
            }
        }
        return $true
    } catch {
        Write-Warning "Exception: $_"
        Write-Warning $_.Exception.ToString()
        return $false
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}