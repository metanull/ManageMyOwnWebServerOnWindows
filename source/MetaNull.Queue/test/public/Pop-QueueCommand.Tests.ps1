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

        It "TestData is initialized" {
            ValidateTestData -TestData $TestData | Should -BeTrue
        }
        It "Should not throw an exception" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                {$Command = Invoke-ModuleFunctionStub -Id $Queue.Id} | Should -Not -Throw
            }
        }
        It "Should pop the last command from the registry" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index = $_.Commands.Index | Select-Object -Last 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id
                Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index" | Should -BeFalse
            }
        }
        It "Should unshift the first command from the registry" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index = $_.Commands.Index | Select-Object -First 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id -Unshift
                Test-Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index" | Should -BeFalse
            }
        }
        It "Should return the popped command from the registry" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $FirstCommand = $_.Commands | Select -First 1
                $Command = Invoke-ModuleFunctionStub -Id $Queue.Id -Unshift
                $Command.Index | Should -Be $FirstCommand.Index
                $Command.Command | Should -Be $FirstCommand.Command
            }
        }
    }
}
