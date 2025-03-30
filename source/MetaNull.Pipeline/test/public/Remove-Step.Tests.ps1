Describe "Remove-Step" -Tag "Functional","BeforeBuild" {

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
            {Invoke-ModuleFunctionStub -Id (New-Guid) -Stage 127 -Job 127 -Step 127} | Should -Throw
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage 127 -Job 127 -Step 127} | Should -Throw
            }
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is valid and Job Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Id -Job 127 -Step 127} | Should -Throw
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
                        $Job.Steps | Foreach-Object {
                            $Step = $_
                            {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Id -Job $Job.Id -Step $Step.Index} | Should -Not -Throw
                        }
                    }
                }
            }
        }
        It "Should remove the desired step" {
            $ToDelete = $TestData.Pipelines | Select-Object -First 1 | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Select-Object -First 1 | Foreach-Object {
                    $Stage = $_
                    $Stage.Jobs | Select-Object -First 1 | Foreach-Object {
                        $Job = $_
                        $Job.Steps | Select-Object -First 1
                    }
                }
            }
            Test-Path "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Steps\$($ToDelete.Index)" | Should -BeTrue
            Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Index -Job $Job.Index -Step $ToDelete.Index
            Test-Path "MetaNull:\Pipelines\$($Pipeline.Id)\Stages\$($Stage.Index)\Jobs\$($Job.Index)\Steps\$($ToDelete.Index)" | Should -BeFalse
        }
    }
}