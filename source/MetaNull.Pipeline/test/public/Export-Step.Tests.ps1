Describe "Export-Step" -Tag "Functional","BeforeBuild" {

    Context "When the function is called" {
        BeforeAll {
            # Load TestData
            . (Join-Path (Split-Path $PSCommandPath) "TestData.ps1")
            $ExportParameters = $TestData.ExportParameters
            if(-not $ExportParameters) {
                throw "ExportParameters not found in TestData"
            }
            if($ExportParameters.OutputDirectory -notlike "$($env:TEMP)\*") {
                throw "ExportParameters.OutputDirectory must be a child of user's Temp directory"
            }

            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                . $FunctionPath @args | write-Output
            }
        }

        AfterAll {
            # Cleanup (remove the whole test registry key)
            DestroyTestData
        }
        BeforeEach {
            # Adding test data to the registry
            InsertTestData -TestData $TestData
            # Creating repositories
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $_.Stages | Foreach-Object {
                    $Stage = $_
                    $_.Jobs | Foreach-Object {
                        $Job = $_
                        New-Item -ItemType Directory -Path "$($ExportParameters.OutputDirectory)\$($Pipeline.Id)\$($Stage.Index)\$($Job.Index)" -Force | Out-Null
                    }
                }
            }
                        
        }
        AfterEach {
            # Cleanup (remove all queues)
            RemoveTestData
            # Removing repositories
            Remove-Item -Force -Recurse -Path $($ExportParameters.OutputDirectory)
        }

        It "TestData is initialized" {
            ValidateTestData -TestData $TestData | Should -BeTrue
        }

        It "Should throw when the Pipeline Id is not found" {
            {Invoke-ModuleFunctionStub @ExportParameters -Id (New-Guid) -Stage 127 -Job 127 -Step 127} | Should -Throw
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                {Invoke-ModuleFunctionStub @ExportParameters -Id $Pipeline.Id -Stage 127 -Job 127 -Step 127} | Should -Throw
            }
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is valid and Job Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    {Invoke-ModuleFunctionStub @ExportParameters -Id $Pipeline.Id -Stage $Stage.Id -Job 127 -Step 127} | Should -Throw
                }
            }
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is valid and Job Index is valid and Step Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Foreach-Object {
                        $Job = $_
                        {Invoke-ModuleFunctionStub @ExportParameters -Id $Pipeline.Id -Stage $Stage.Id -Job $Job.Id -Step 127} | Should -Throw
                    }
                }
            }
        }

        It "Should generate a `$StepIndex.ps1 script file for each step in directory `$OutputDirectory\`$PipeLineId\`$StageIndex\`$JobIndex and return its absolute path" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Foreach-Object {
                        $Job = $_
                        $Job.Steps | Foreach-Object {
                            $Step = $_
                            $Step | ForEach-Object {
                                $DesiredOutFile = "$($ExportParameters.OutputDirectory)\$($Pipeline.Id)\$($Stage.Index)\$($Job.Index)\$($Step.Index).ps1"
                                $Result = Invoke-ModuleFunctionStub @ExportParameters -Id $Pipeline.Id -Stage $Stage.Index -Job $Job.Index -Step $Step.Index
                                $Result | Should -Be $DesiredOutFile
                                Test-Path $Result | Should -BeTrue
                            }
                        }
                    }
                }
            }
        }
        It "Should generate a `$StepIndex.ps1 script file containing the Step's commands" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Foreach-Object {
                        $Job = $_
                        $Job.Steps | Foreach-Object {
                            $Step = $_
                            $Step | ForEach-Object {
                                $Result = Invoke-ModuleFunctionStub @ExportParameters -Id $Pipeline.Id -Stage $Stage.Index -Job $Job.Index -Step $Step.Index
                                $Content = Get-Content $Result
                                $Content -join "`n" | Should -Contain $Step.Commands -join "`n"
                            }
                        }
                    }
                }
            }
        }
    }
}