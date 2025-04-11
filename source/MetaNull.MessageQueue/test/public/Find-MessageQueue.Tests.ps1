Describe "Find-MessageQueue" -Tag "Functional","BeforeBuild" {

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
                . $FunctionPath @args | Write-Output
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
        
        It "Should not throw an exception when name is '*'" {
            {Invoke-ModuleFunctionStub -Name '*'} | Should -Not -Throw
        }
        It "Should not throw an exception when name is not found" {
            {Invoke-ModuleFunctionStub -Name 'NOT-EXISTING-TEST-QUEUE'} | Should -Not -Throw
        }
        It "Should return all message queues when name is '*'" {
            $Result = Invoke-ModuleFunctionStub
            $Result.Count | Should -Be $TestData.Count
            0..($Result.Count) | Foreach-Object {
                $TestData.MessageQueueId | Should -Contain $Result[0]
            }
        }
        It "Should return expected Id when name is 'TEST:1*'" {
            $Result = Invoke-ModuleFunctionStub -Name 'TEST:1*'
            ($TestData | Where-Object {$_.Name -like 'TEST:1*'}).MessageQueueId | Should -Be $Result
        }
        It "Should return expected Id when name is 'TEST:2*'" {
            $Result = Invoke-ModuleFunctionStub -Name 'TEST:2*'
            ($TestData | Where-Object {$_.Name -like 'TEST:2*'}).MessageQueueId | Should -Be $Result
        }
    }
}
