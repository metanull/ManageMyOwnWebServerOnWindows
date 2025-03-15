Describe "New-Queue" -Tag "UnitTest" {

    Context "When Install-Queues was not called" {
        
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')

            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                . $FunctionPath @args | write-Output
            }
            Function Get-RegistryPath {
                param([string] $ChildPath)
                return "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\$ChildPath"
            }
            Function Lock-ModuleMutex {
                return $true
            }
            Function Unlock-ModuleMutex {
                return $true
            }
        }

        It "It should throw an exception" {
            {Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_30" -Description "NewQueuesTests_30"} | Should -Throw
        }
        
    }

    Context "When calling install-Queues" {
        
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')

            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                . $FunctionPath @args | write-Output
            }
            Function Get-RegistryPath {
                param([string] $ChildPath)
                return "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\$ChildPath"
            }
            Function Test-QueuesInstalled {
                return $false
            }
            Function Lock-ModuleMutex {
                return $true
            }
            Function Unlock-ModuleMutex {
                return $true
            }
        }
        BeforeEach {
            $I = New-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized" -Force | Out-Null
            $I | New-ItemProperty -Name 'Initialized' -Value 1 -PropertyType 'DWord' | Out-Null
            $I = New-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues" -Force | Out-Null
        }
        AfterEach {
            Remove-Item -Force -Recurse -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue
        }

        It "Queue's Registry key should exist" {
            Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_78" -Description "NewQueuesTests_78"
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues\NewQueuesTests_78" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "Queue's Registry key should have a [GUID]'Id' property" {
            Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_82" -Description "NewQueuesTests_82"
            $Item = Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues\NewQueuesTests_82"
            $Property = $Item | Get-ItemProperty -Name 'Id' -ErrorAction SilentlyContinue
            {[guid]::new($Property.Id)} | Should -Not -Throw
        }
        It "Queue's Registry key should return a [GUID]" {
            $ReturnedId = Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_88" -Description "NewQueuesTests_88"
            {[guid]::new($ReturnedId)} | Should -Not -Throw
        }
        It "Queue's Registry key property Id should be the same as the returned [GUID]" {
            $ReturnedId = Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_91" -Description "NewQueuesTests_91"
            $RegistryId = Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues\NewQueuesTests_91" | Get-ItemPropertyValue -Name 'Id'
            $ReturnedId | Should -Be $RegistryId
        }
        It "Queue's Registry key should have a 'Commands' child key" {
            Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_96" -Description "NewQueuesTests_96"
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues\NewQueuesTests_96\Commands" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "The 'Commands' child key should be empty" {
            Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_101" -Description "NewQueuesTests_101"
            Get-ChildItem -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues\NewQueuesTests_101\Commands" -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
        It "Queue's Registry key should have the required default properties" {
            Invoke-ModuleFunctionStub -Scope AllUsers -QueueName "NewQueuesTests_105" -Description "NewQueuesTests_105"
            $Item = Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Queues\NewQueuesTests_105"
            $Properties = $Item | Get-ItemProperty -ErrorAction SilentlyContinue
            $Properties.Id | Should -Not -BeNullOrEmpty
            $Properties.Description | Should -Be 'NewQueuesTests_105'
            $Properties.Status | Should -Be 'Iddle'
            $Properties.CreatedDate | Should -Not -BeNullOrEmpty
            $Properties.ModifiedDate | Should -Not -BeNullOrEmpty
            $Properties.StartCount | Should -Be 0
            $Properties.FailureCount | Should -Be 0
            $Properties.Disabled | Should -Be 0
            $Properties.Suspended | Should -Be 0
            $Properties.DisabledDate | Should -BeNullOrEmpty
            $Properties.SuspendedDate | Should -BeNullOrEmpty
            $Properties.LastStartedDate | Should -BeNullOrEmpty
            $Properties.LastFinishedDate | Should -BeNullOrEmpty
            $Version = $Properties.Version | ConvertFrom-Json
            $Version.Major | Should -Be 0
            $Version.Minor | Should -Be 0
            $Version.Build | Should -Be 0
            $Version.Revision | Should -Be 0
        }
    }
}
