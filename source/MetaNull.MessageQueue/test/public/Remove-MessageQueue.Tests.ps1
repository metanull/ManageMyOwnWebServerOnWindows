Describe "Remove-MessageQueue" -Tag "Functional","BeforeBuild" {

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

    Context "When the Mesage Queue Is Populated" {
        
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
            {
                Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Select-Object -ExpandProperty PSChildName | Foreach-Object {
                    Invoke-ModuleFunctionStub -MessageQueueId $_ -ErrorAction Stop
                }
            } | Should -Not -Throw
        }
        It "Should not output anything" {
            $Result = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Select-Object -ExpandProperty PSChildName | Foreach-Object {
                Invoke-ModuleFunctionStub -MessageQueueId $_ -ErrorAction Stop
            }
            $Result | Should -BeNullOrEmpty
        }
        It "Should remove the Message Queues" {
            Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Select-Object -ExpandProperty PSChildName | Foreach-Object {
                Invoke-ModuleFunctionStub -MessageQueueId $_
            }
            $TestData | Foreach-Object {
                $Data = $_
                {Get-Item -Path "MetaNull:\MessageQueue\$($Data.MessageQueueId)" -ErrorAction Stop} | Should -Throw
            }
        }

        It "Should leave the Message Store untouched" {
            $Before = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $Result = Get-Item -Path MetaNull:\MessageQueue | Get-ChildItem | Select-Object -ExpandProperty PSChildName | Foreach-Object {
                Invoke-ModuleFunctionStub -MessageQueueId $_
            }
            $After = Get-Item -Path MetaNull:\MessageStore | Get-ChildItem | Select-Object -ExpandProperty PSChildName
            $After.Count | Should -BeGreaterThan 0
            $Before.Count | Should -Be $After.Count
            $After.Count | Should -Be $TestData.Messages.Count
        }
    }
}
