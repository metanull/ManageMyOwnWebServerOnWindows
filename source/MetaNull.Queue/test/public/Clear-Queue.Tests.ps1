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
            Remove-Item -Force -Recurse -Path MetaNull:\ -ErrorAction SilentlyContinue  | Out-Null
            Remove-PSDrive -Name MetaNull -Scope Script -ErrorAction SilentlyContinue
        }
        BeforeEach {
            # Adding test data to the registry
            $TestData | Foreach-Object {
                $Id = $_.Queue.Id
                $Properties = $_.Queue
                New-Item "MetaNull:\Queues\$Id\Commands" -Force | Out-Null
                $Item = Get-Item "MetaNull:\Queues\$Id"
                $Properties.GetEnumerator() | ForEach-Object {
                    $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                }
                $_.Commands | Foreach-Object {
                    $Item = New-Item -Path "MetaNull:\Queues\$Id\Commands\$($_.Index)" -Force
                    $_.GetEnumerator() | ForEach-Object {
                        $Item | New-ItemProperty -Name $_.Key -Value $_.Value | Out-Null
                    }
                }
            }
        }
        AfterEach {
            # Cleanup (remove all queues)
            Remove-Item -Force -Recurse -Path MetaNull:\Queues\* -ErrorAction SilentlyContinue  | Out-Null
        }

        It "Test environment PSDrive should be initialized" {
            $MetaNull.Queue.Drive | Should -Not -BeNullOrEmpty
            {Get-PSDrive -Name 'MetaNull'} | Should -Not -Throw
            Get-PSDrive -Name 'MetaNull' | Should -Not -BeNullOrEmpty
            Test-Path MetaNull:\Queues | Should -BeTrue
        }
        It "Test environment should be initialized and test queue exists" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands" | Should -BeTrue
                (Get-ChildItem "MetaNull:\Queues\$($Queue.Id)\Commands").Count | Should -Be $($_.Commands.Count)
                $_.Commands | Foreach-Object {
                    Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)" | Should -BeTrue
                }
            }
        }
        It "Should not throw an exception" {
            $TestData | Foreach-Object {
                {Invoke-ModuleFunctionStub -Id $_.Queue.Id} | Should -Not -Throw
            }
        }
        It "Should not remove the 'Commands' directory from the registry" {
            $TestData | Foreach-Object {
                Invoke-ModuleFunctionStub -Id $_.Queue.Id
                Test-Path "MetaNull:\Queues\$($_.Queue.Id)\Commands" | Should -BeTrue
            }
        }
        It "Should remove each individual Command from the registry" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $_.Commands | Foreach-Object {
                    Invoke-ModuleFunctionStub -Id $Queue.Id
                    Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$($_.Index)" | Should -BeFalse
                }
                (Get-ChildItem "MetaNull:\Queues\$($Queue.Id)\Commands").Count | Should -Be 0
            }

        }
    }
}
