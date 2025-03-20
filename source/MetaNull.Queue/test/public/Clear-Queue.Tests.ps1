Describe "Clear-Queue" -Tag "Functional","BeforeBuild" {

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
        
        It "Should not throw an exception" {
            $TestData.Queues | Foreach-Object {
                {Invoke-ModuleFunctionStub -Id $_.Id} | Should -Not -Throw
            }
        }
        It "Should not remove the 'Commands' directory from the registry" {
            $TestData.Queues | Foreach-Object {
                Invoke-ModuleFunctionStub -Id $_.Id
                Test-Path "MetaNull:\Queues\$($_.Id)\Commands" | Should -BeTrue
            }
        }
        It "Should remove each individual Command from the registry" {
            $TestData.Queues | Foreach-Object {
                $Queue = $_
                $_.Commands | Foreach-Object {
                    Invoke-ModuleFunctionStub -Id $Queue.Id
                    Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)" | Should -BeFalse
                }
                (Get-ChildItem "MetaNull:\Queues\$($Queue.Id)\Commands").Count | Should -Be 0
            }

        }
    }
}
