Describe "Resolve-QueueName" -Tag "Functional","BeforeBuild" {

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
        
        It "Completion Should return all Queues when PartialName is *" {
            $Result = Invoke-ModuleFunctionStub -PartialName '*'
            $Result.Count | Should -Be $TestData.Queues.Count
        }
        It "Completion Should return the expected Name when exact value provided" {
            $TestData.Queues | Foreach-Object {
                $CurrentTest = $_
                $Result = Invoke-ModuleFunctionStub -PartialName $CurrentTest.Name
                $Result | Should -Be $CurrentTest.Name
            }
        }
        It "Completion Should return the expected Name when partial value provided" {
            $TestData.Queues | Foreach-Object {
                $CurrentTest = $_
                $Result = Invoke-ModuleFunctionStub -PartialName ($CurrentTest.Name -replace '...$','*')
                $Result | Should -Be $CurrentTest.Name
            }
        }
        It "Should return nothing when Name is not found" {
            $Result = Invoke-ModuleFunctionStub -PartialName (New-Guid).ToString()
            $Result | Should -BeNullOrEmpty
        }
    }
}
