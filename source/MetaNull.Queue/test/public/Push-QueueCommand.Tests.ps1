Describe "Push-QueueCommand" -Tag "Functional","BeforeBuild" {

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
                {$Index = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-66' -Command 'Test-66'} | Should -Not -Throw
            }
        }
        It "Should add the command to the registry" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-72' -Command 'Test-72'
                $Index | Should -Not -BeNullOrEmpty
                $Item = Get-Item -Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index"
                $Item | Should -Not -BeNullOrEmpty
                $Item | Get-ItemPropertyValue -Name 'Command' | Should -Be 'Test-72'
                $Item | Get-ItemPropertyValue -Name 'Index' | Should -Be $Index
            }
        }
        It "Should increment the Index automatically" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index1 = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-85.1' -Command 'Test-85.1'
                $Index2 = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-85.2' -Command 'Test-85.2'
                $Index3 = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-85.3' -Command 'Test-85.3'
                $Index1 | Should -Not -BeNullOrEmpty
                $Index2 | Should -Not -BeNullOrEmpty
                $Index3 | Should -Not -BeNullOrEmpty
                $Index1 | Should -Not -Be $Index3
                $Index2 | Should -Be ($Index1 + 1)
                $Index3 | Should -Be ($Index2 + 1)
            }
        }
        It "Should support Type String" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-97' -Command 'Test-97'
                $Index | Should -Not -BeNullOrEmpty
                $Item = Get-Item -Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index"
                $Item | Should -Not -BeNullOrEmpty
                $Item | Get-ItemPropertyValue -Name 'Command' | Should -Be 'Test-97'
                $Item | Get-ItemPropertyValue -Name 'Index' | Should -Be $Index
            }
        }
        It "Should support Type ExpandString" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-108' -ExpandableCommand '%USERNAME%'
                $Index | Should -Not -BeNullOrEmpty
                $Item = Get-Item -Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index"
                $Item | Should -Not -BeNullOrEmpty
                $Item | Get-ItemPropertyValue -Name 'Command' | Should -Be $env:USERNAME
                $Item | Get-ItemPropertyValue -Name 'Index' | Should -Be $Index
            }
        }
        It "Should support Type MultiString" {
            $TestData | Foreach-Object {
                $Queue = $_.Queue
                $Index = Invoke-ModuleFunctionStub -Id $Queue.Id -Name 'Test-119' -Commands 'Hello','World','42'
                $Index | Should -Not -BeNullOrEmpty
                $Item = Get-Item -Path "MetaNull:\Queues\$($Queue.Id)\Commands\$Index"
                $Item | Should -Not -BeNullOrEmpty
                $Item | Get-ItemPropertyValue -Name 'Index' | Should -Be $Index
                $Item | Get-ItemPropertyValue -Name 'Command' | Should -BeOfType [System.Array]
                ($Item | Get-ItemPropertyValue -Name 'Command').Count | Should -Be 3
                ($Item | Get-ItemPropertyValue -Name 'Command')[0] | Should -Be 'Hello'
                ($Item | Get-ItemPropertyValue -Name 'Command')[1] | Should -Be 'World'
                ($Item | Get-ItemPropertyValue -Name 'Command')[2] | Should -Be '42'
                
            }
        }
    }
}
