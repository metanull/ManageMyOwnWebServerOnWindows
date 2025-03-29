Describe "Get-Step" -Tag "Functional","BeforeBuild" {

    Context "When the function is called" {
        BeforeAll {
            # Load TestData
            . (Join-Path (Split-Path $PSCommandPath) "TestData.ps1")

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
        }
        AfterEach {
            # Cleanup (remove all queues)
            RemoveTestData
        }

        It "TestData is initialized" {
            ValidateTestData -TestData $TestData | Should -BeTrue
        }

        It "Should throw when the Pipeline Id is not found" {
            {Invoke-ModuleFunctionStub -Id (New-Guid) -Stage 127 -Job 127} | Should -Throw
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage 127 -Job 127} | Should -Throw
            }
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is valid and Job Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Id -Job 127} | Should -Throw
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
                        {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Id -Job $Job.Id -Step 127} | Should -Throw
                    }
                }
            }
        }
        It "Should not throw an exception when Pipeline Id is given and Stage Index is given and Job Index is given but no Step Index is given" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Foreach-Object {
                        $Job = $_
                        {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Id -Job $Job.Id} | Should -Not -Throw
                    }
                }
            }
        }
        It "Should return all steps when Pipeline Id is provided and Stage Index is given and Job Index is given but no Step Index is given" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Foreach-Object {
                        $Job = $_
                        $Result = Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Index -Job $Job.Index
                        $Result.Count | Should -Be $Pipelines.Stages.Jobs.Steps.Count
                    }
                }
            }
        }
        It "Should return the expected data when the Pipeline Id is provided and Stage Index is given and Job Index is given as well as the Step Index" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Foreach-Object {
                        $Job = $_
                        $Job.Steps | Foreach-Object {
                            $Step = $_
                            $Result = Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Index -Job $Job.Index -Step $Step.Index
                            $Result | Should -BeOfType [PSCustomObject]
                            $Result.Index | Should -Be $Step.Index
                            $Result.Name | Should -Be $Step.Name
                            ($Result.Commands -join "`n") | Should -Be ($Step.Commands  -join "`n")
                        }
                    }
                }
            }
        }
    }
}