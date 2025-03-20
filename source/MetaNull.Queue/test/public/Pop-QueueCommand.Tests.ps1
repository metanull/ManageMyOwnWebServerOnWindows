Describe "Pop-QueueCommand" -Tag "Functional","BeforeBuild" {

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
                $Queue = $_
                {$Command = Invoke-ModuleFunctionStub -Id $Queue.Id} | Should -Not -Throw
            }
        }
        It "Should pop the last command from the registry" {
            $TestData.Queues | Foreach-Object {
                $Queue = $_
                $Index = $_.Commands.Index | Select-Object -Last 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id
                Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index" | Should -BeFalse
            }
        }
        It "Should unshift the first command from the registry" {
            $TestData.Queues | Foreach-Object {
                $Queue = $_
                $Index = $_.Commands.Index | Select-Object -First 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id -Unshift
                Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index" | Should -BeFalse
            }
        }
        It "Should return the popped command from the registry" {
            $TestData.Queues | Foreach-Object {
                $Queue = $_
                $FirstCommand = $_.Commands | Select-Object -First 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id -Unshift
                $Command.Index | Should -Be $FirstCommand.Index
                $Command.Command | Should -Be $FirstCommand.Command
            }
        }
        It "Should provide a ToScriptblock ScriptMethod" {
            $TestData.Queues | Foreach-Object {
                $Queue = $_
                $FirstCommand = $_.Commands | Select-Object -First 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id -Unshift
                $Command.ToScriptBlock() | Should -BeOfType [System.Management.Automation.ScriptBlock]
                $Command.ToScriptBlock().Invoke() | Should -Be $FirstCommand.Output
            }
        }
    }
}
