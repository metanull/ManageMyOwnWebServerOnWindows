Describe "Get-Stage" -Tag "Functional","BeforeBuild" {

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
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
        It "Should throw when the Pipeline Id is valid and Stage Index is not found" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                {Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage 127} | Should -Throw
            }
        }
        It "Should not throw an exception when Pipeline Id is given but no Stage Index is given" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    {Invoke-ModuleFunctionStub -Id $Pipeline.Id} | Should -Not -Throw
                }
            }
        }
        It "Should return all stages when Pipeline Id is provided and no Stage Index is given" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Result = Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Index
                    $Result.Count | Should -Be $Pipelines.Stages.Count
                }
            }
        }
        It "Should return the expected data when the Pipeline Id is provided as well as the Stage Index" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Pipeline.Stages | Foreach-Object {
                    $Stage = $_
                    $Result = Invoke-ModuleFunctionStub -Id $Pipeline.Id -Stage $Stage.Index
                    $Result | Should -BeOfType [PSCustomObject]
                    $Result.Index | Should -Be $Stage.Index
                    $Result.Name | Should -Be $Stage.Name
                    $Result.Jobs | Should -Not -BeNullOrEmpty
                    $Result.Jobs.Count | Should -Be $Stage.Jobs.Count
                }
            }
        }
        
    }
}