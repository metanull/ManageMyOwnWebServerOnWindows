Describe "Get-Queue" -Tag "Functional","BeforeBuild" {

    Context "When the function is called" {
        
        BeforeAll {
            # Load TestData
            . (Join-Path (Split-Path $PSCommandPath) "TestData.ps1")
            
            # Initialize tests (get references to Module Function's Code)
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            # Create a Stub for the module function to test
            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
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
        
        It "Should not throw an exception - by Id" {
            $TestData.Queues | Foreach-Object {
                {Invoke-ModuleFunctionStub -Id $_.Id} | Should -Not -Throw
            }
        }
        It "Should return all  Queues when no Id is provided" {
            $Result = Invoke-ModuleFunctionStub
            $Result.Count | Should -Be $TestData.Queues.Count
        }
        It "Should return the expected when the Id is provided" {
            $TestData.Queues | Foreach-Object {
                $CurrentTest = $_
                $Result = Invoke-ModuleFunctionStub -Id $CurrentTest.Id
                $Result | Should -BeOfType [PSCustomObject]
                $Result.Id | Should -Be $CurrentTest.Id
                $Result.Name | Should -Be $CurrentTest.Name
                $Result.Description | Should -Be $CurrentTest.Description
                $Result.Status | Should -Be $CurrentTest.Status
            }
        }
        It "Should throw when the Id is not found" {
            {Invoke-ModuleFunctionStub -Id (New-Guid)} | Should -Throw
        }
    }
}
