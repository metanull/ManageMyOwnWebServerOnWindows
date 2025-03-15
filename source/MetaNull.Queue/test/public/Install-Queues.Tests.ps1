Describe "Install-Queues" -Tag "UnitTest" {

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
        }

        It "Registry key should not exist" {
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
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
            Invoke-ModuleFunctionStub -Force
        }
        AfterEach {
            Remove-Item -Force -Recurse -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue
        }

        It "Registry key MetaNull.Queue should exist" {
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "Registry key MetaNull.Queue\Initialized should exist" {
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It "Registry key MetaNull.Queue\Initialized should have an 'Initialized' property = 1" {
            $Item = Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized"
            $Item.GetValue("Initialized") | Should -Be 1
        }
    }
}
