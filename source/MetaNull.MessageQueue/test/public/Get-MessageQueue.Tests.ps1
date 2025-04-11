Describe "Get-MessageQueue" -Tag "Functional","BeforeBuild" {
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
        
        It "Should not throw an exception when MessageQueueId is found" {
            {Invoke-ModuleFunctionStub -MessageQueueId ($TestData[0].MessageQueueId)} | Should -Not -Throw
        }
        It "Should throw when MessageQueueId is not found" {
            {Invoke-ModuleFunctionStub -MessageQueueId (New-Guid)} | Should -Throw
        }
        It "Should return the expected data when MessageQueueId is valid" {
            $TestData | Foreach-Object {
                $Data = $_
                $Result = Invoke-ModuleFunctionStub -MessageQueueId $Data.MessageQueueId
                $Result.MessageQueueId | Should -Be $Data.MessageQueueId
                $Result.Name | Should -Be $Data.Name
                $Result.MaximumSize | Should -Be $Data.MaximumSize
                $Result.MessageRetentionPeriod | Should -Be $Data.MessageRetentionPeriod
            }
        }
    }
}
