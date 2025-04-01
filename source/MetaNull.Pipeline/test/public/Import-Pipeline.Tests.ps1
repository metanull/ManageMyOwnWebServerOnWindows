Describe "Import-Pipeline" -Tag "Functional","BeforeBuild" {

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

        It "Should not throw when no paramters are given" {
            {Invoke-ModuleFunctionStub} | Should -Not -Throw
        }
        It "Should throw when an invalid ID is provided" {
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
        It "Should return the expected number of objects when no parameters are given" {
            $Result = Invoke-ModuleFunctionStub
            $Result.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Count | Should -Be 2
            $Result[0].Name | Should -BeIn $TestData.Pipelines.Name
            $Result[1].Name | Should -BeIn $TestData.Pipelines.Name
            $Result[0].Name | Should -Not -Be $Result[1].Name
        }
        It "Should return one single object when a valid Id is provided" {
            $Result = Invoke-ModuleFunctionStub -Id ($TestData.Pipelines[1].Id)
            $Result.GetType().FullName | Should -Be 'System.Management.Automation.PSCustomObject'
            $Result.Name | Should -Be $TestData.Pipelines[1].Name
            $Result.Stages.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Stages.Count | Should -BeGreaterThan 0
            $Result.Stages.Count | Should -Be $TestData.Pipelines[1].Stages.Count
            $Result.Stages[0].Name | Should -BeIn $TestData.Pipelines[1].Stages.Name
            $Result.Stages[1].Name | Should -BeIn $TestData.Pipelines[1].Stages.Name
            Read-Host "PipelineId: $($TestData.Pipelines[1].Id)"
        }
    }
}