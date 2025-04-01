Describe "Import-Pipeline" -Tag "UnitTest","BeforeBuild" {

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

        It "Should throw when the Id is not found" {
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
        It "Should not throw an exception when Id is given and valid" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                {Invoke-ModuleFunctionStub -Id $Pipeline.Id} | Should -Not -Throw
            }
        }
        It "Should return all pipelines when no Id is provided" {
            $Result = Invoke-ModuleFunctionStub
            $Result.Count | Should -Be $TestData.Pipelines.Count
        }
        It "Should return the expected data when the Id is provided" {
            $TestData.Pipelines | Foreach-Object {
                $Pipeline = $_
                $Result = Invoke-ModuleFunctionStub -Id $Pipeline.Id
                $Result | Should -BeOfType [PSCustomObject]
                $Result.Id | Should -Be $Pipeline.Id
                $Result.Name | Should -Be $Pipeline.Name
                $Result.Description | Should -Be $Pipeline.Description
                $Result.Stages | Should -Not -BeNullOrEmpty
                $Result.Stages.Count | Should -Be $Pipeline.Stages.Count
            }
        }
    }
}