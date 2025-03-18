Describe "New-Queue" -Tag "Functional","BeforeBuild" {

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
            {Invoke-ModuleFunctionStub -Name 'Test-44'} | Should -Not -Throw
        }
        It "Should modify the registry" {
            Invoke-ModuleFunctionStub -Name 'Test-47'
            Get-ChildItem -Path MetaNull:\Queues | Should -Not -BeNullOrEmpty
        }
        It "Should add the queue to the registry" {
            Invoke-ModuleFunctionStub -Name 'Test-51'
            $Item = Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-51'
            }
            $Item | Should -Not -BeNullOrEmpty
        }
        It "Should add the queue to the registry with an empty Description" {
            Invoke-ModuleFunctionStub -Name 'Test-58'
            $Item = Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-58'
            }
            $Item | Get-ItemPropertyValue -Name 'Description' | Should -BeNullOrEmpty
        }
        It "Should add the queue to the registry with an 'iddle' Status" {
            Invoke-ModuleFunctionStub -Name 'Test-66'
            $Item = Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-66'
            }
            $Item | Get-ItemPropertyValue -Name 'Status' | Should -Be 'Iddle'
        }
        It "Should add the queue to the registry with the right Description" {
            Invoke-ModuleFunctionStub -Name 'Test-72' -Description 'Test Description'
            $Item = Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-72'
            }
            $Item | Get-ItemPropertyValue -Name 'Description' | Should -Be 'Test Description'
        }
        It "Should add the queue to the registry with the right Description" {
            Invoke-ModuleFunctionStub -Name 'Test-80' -Status 'Disabled'
            $Item = Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-80'
            }
            $Item | Get-ItemPropertyValue -Name 'Status' | Should -Be 'Disabled'
        }
        It "Should add the queue to the registry with the right children" {
            Invoke-ModuleFunctionStub -Name 'Test-86' -Status 'Disabled'
            $Id = Get-ChildItem -Path MetaNull:\Queues | Where-Object {
                ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name) -eq 'Test-86'
            } | Get-ItemProperty | Select-Object -ExpandProperty Id
            Test-Path "MetaNull:\Queues\$Id\Commands" | Should -BeTrue
        }
    }
}
